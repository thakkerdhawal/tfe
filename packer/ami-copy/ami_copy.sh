#!/bin/bash
#
# Copy an AMI to another account maintaining encryption
#
# User needs to supply a Source CMK key and a Destination one for the new account
#
# The user running the script also needs to be a member of these groups.
# The script will handle if the source AMI was created with the default AWS encryption as it creates the new AMI with the supplied keys in the new account.

# The source profile and destination profile must have already been specified in the users ~/.aws/config file. The access to AWS must also be specified in their ~/.aws/credentials file

set -o errexit
TEMP_KMS_KEY_CREATED=false

######################################################################################################################################################################
#
# FUNCTIONS
#
######################################################################################################################################################################

function usage()
{
    echo " Usage: ${0} -p SRC_PROFILE -r SRC_REGION -P DST_PROFILE -R DST_REGION -a AMI_ID [-k SRC_CMK_ID -K DST_CMK_ID]
    -p,               AWS CLI profile name for AMI source account.
    -r,               AWS region for AMI source account.
    -P,               AWS CLI profile name for AMI destination account. 
    -R,               AWS region for AMI destination account. 
    -a,               ID of AMI to be copied.
    [-k,              Optional: specific KMS Source Customer Managed Key (CMK) ID for snapshot re-encryption in source AWS account.]
    [-K,              Optional: specific KMS Dest Customer Managed Key (CMK) ID for snapshot re-encryption in target AWS account. The default KMS key for EBS volume will be used if omit.]
    [-h,              Show this message.]

    Typical usage:

 	ami_copy.sh -p nwmss_test -r eu-west-2 -P nwm_test -R eu-west-1 -a ami-5a9e8eb0 
    "
}


function die()
{
    BASE=$(basename -- "$0")
    echo -e "${RED} $BASE: error: $@ ${NC}" >&2
    exit 1
}

function validate_cmk() {
  local PROFILE=$1
  local REGION=$2
  local KEY_ID=$3

  # Check if dest key exists and is available to use
  if [ "$(aws --profile ${PROFILE} --region ${REGION}  kms describe-key --key-id ${KEY_ID} --query 'KeyMetadata.Enabled' --output text)" == "True" ]; then
	 echo -e "${COLOR}Validated KMS Key:${NC} ${KEY_ID}"
  else
        die "KMS Key ${KEY_ID} non existent, in the wrong region, or not enabled. Aborting."
  fi
  # Check if the key provided is customer managed 
  if [ "$(aws --profile ${PROFILE} --region ${REGION}  kms describe-key --key-id ${KEY_ID} --query 'KeyMetadata.KeyManager' --output text)" == "CUSTOMER" ]; then
     echo -e "${COLOR}Validated KMS Key is customer managed:${NC} ${KEY_ID}"
  else
     die "The provided source KMS Key is not customer managed. Either provide a valid CMK or leave it alone."
  fi
}

function validate_profile() {
  local PROFILE=$1
  local REGION=$2
  local NAME=$3
  if [[ "$(aws ec2 describe-regions --region-name ${REGION} --profile ${PROFILE} --region ${REGION} --query 'Regions[0].RegionName' --output text)" == "${REGION}" ]]; then
     echo -e "${COLOR}${NAME} region:${NC}" ${REGION}
  else
     die "Invalid region: ${REGION}"
  fi
}
 
function get_ami_details() {
  local PROFILE=$1
  local REGION=$2
  local AMI_ID=$3

  # Describes the source AMI and stores its contents
  AMI_DETAILS=$(aws ec2 describe-images --profile ${PROFILE} --region ${REGION} --image-id ${AMI_ID} --query 'Images[0]')|| die "Unable to describe the AMI in the source account. Aborting."
  echo -e "${COLOR}Found AMI: ${NC}" ${AMI_ID}

  ## ensure the Source AMI is encrypted already or we arent continuing as there should be no unencrypted AMIs
  IS_ENCRYPTED=$(echo "${AMI_DETAILS}" | jq -r '.BlockDeviceMappings[0].Ebs.Encrypted')
  echo -e "${COLOR}AMI encryption status: ${NC}" ${IS_ENCRYPTED}

  ### echo "IS_ENCRYPTED = ${IS_ENCRYPTED}"
  # TODO: allow copy of unencrypted ami

  if [ "${IS_ENCRYPTED}" != "true" ]
  then
	 die "Source AMI-ID ${AMI_ID} is not Encrypted. Aborting."
  fi
}

# does the AMI exist already in the Destination area
function check_dest_for_ami() {

  # describe all the instances in dest and search for our ami-id in the name
  ALL_DEST_AMIS=$(aws ec2 describe-images --profile ${DST_PROFILE} --region ${DST_REGION} --filters "Name=is-public,Values=false" --query 'Images[*].[ImageId, Name]' --output text) || die "Can't Fetch AMI Details from ${DST_ACCT_ID}  Account"
  AMI_IN_USE=`grep "${AMI_ID}" <<< "${ALL_DEST_AMIS}" | awk '{print($1)}'`
  if [ "${AMI_IN_USE}" ]
  then
	 die "Source Ami - ${AMI_ID} Is Already Copied To Dest Account ${DST_ACCT_ID} With AMI - ${AMI_IN_USE}"
  fi
}

function validate_params() {
  # Validating Input parameters
  if [ "${SRC_PROFILE}x" == "x" ] || [ "${SRC_REGION}x" == "x" ] || [ "${DST_PROFILE}x" == "x" ] || [ "${AMI_ID}x" == "x" ] || [ "${DST_REGION}x" == "x" ]; then
     usage
     die "Missing required input."
     exit 1;
  fi

  if [[ "${SRC_PROFILE}" == "${DST_PROFILE}" ]] && [[ "${SRC_REGION}" == "${DST_REGION}" ]]; then
     usage
     die "Destination account and region cannot both be as same as source."
     exit 1;
  fi

  validate_profile ${SRC_PROFILE} ${SRC_REGION} "Source"
  SRC_ACCT_ID=$(aws sts get-caller-identity --profile ${SRC_PROFILE} --query Account --output text || die "Unable to get the source account ID. Aborting.")
  echo -e "${COLOR}Source account ID:${NC}" ${SRC_ACCT_ID}
  
  validate_profile ${DST_PROFILE} ${DST_REGION} "Destination"
  DST_ACCT_ID=$(aws sts get-caller-identity --profile ${DST_PROFILE} --query Account --output text || die "Unable to get the destination account ID. Aborting.")
  echo -e "${COLOR}Destination account ID:${NC}" ${DST_ACCT_ID}

  get_ami_details ${SRC_PROFILE} ${SRC_REGION} ${AMI_ID}
  check_dest_for_ami

  [[ "${SRC_CMK_ID}x" != "x" ]] && validate_cmk ${SRC_PROFILE} ${SRC_REGION} ${SRC_CMK_ID}
  if [[ "${DST_CMK_ID}x" != "x" ]]; then
    validate_cmk ${DST_PROFILE} ${DST_REGION} ${DST_CMK_ID}
  else
    # No destination key provided, use default KMS key
    echo -e "${COLOR}No desination key provided, will use default KMS key.${NC}"
    for i in $(aws kms list-keys --profile ${DST_PROFILE} --region ${DST_REGION} --query 'Keys[*].KeyId' --output text); do 
      KEY_INFO=$(aws kms describe-key --profile ${DST_PROFILE} --region ${DST_REGION} --key-id $i --query 'KeyMetadata.{KeyManager:KeyManager,Description:Description}' --output json)
      if [[ $(echo ${KEY_INFO} | jq -r '.KeyManager') == "AWS" ]] && [[ $(echo ${KEY_INFO} | jq -r '.Description') == "Default master key that protects my EBS volumes when no other key is defined" ]]; then
        DST_CMK_ID=$i
        echo -e "${COLOR}Found default KMS key for EBS in dest account:${NC} ${DST_CMK_ID}"
        break
      fi
    done
  fi
  CMK_OPT="--kms-key-id ${DST_CMK_ID}"
}

function retrieve_source_ami_snapshot()
{

# Retrieve the snapshots and key ID's
SNAPSHOT_ID=$(echo ${AMI_DETAILS} | jq -r '.BlockDeviceMappings[].Ebs | .SnapshotId' || die "Unable to get the encrypted snapshot ids from AMI. Aborting.")
echo -e "${COLOR}Snapshot found:${NC}" ${SNAPSHOT_ID}

# keep this if we have key issues for later
ORIG_SNAPSHOT_ID=${SNAPSHOT_ID}

# get the details for the snapshot as we want to add the tags later
GET_SOURCE_SNAP_TAGS="$(aws ec2 describe-snapshots --profile ${SRC_PROFILE} --region ${SRC_REGION} --snapshot-id ${SNAPSHOT_ID} --query 'Snapshots[0].Tags[]')"

NEW_SNAP_TAGS="$(echo ${GET_SOURCE_SNAP_TAGS} | jq -c .)"

# echo "NEW_SNAP_TAGS = 
# ${NEW_SNAP_TAGS}
# "

# aws ec2 describe-snapshots --snapshot-id ${SNAPSHOT_ID}

}

function create_cmk_grant() {
  local PROFILE=$1
  local REGION=$2
  local ACCOUNT=$3
  local CMK_ID=$4

  if GRANTS=$(aws kms --profile ${PROFILE} --region ${REGION} list-grants --key-id ${CMK_ID}); then
    # NOTE: Grant is created on root at the moment, may consider using specific user ARN
    if [[ $(echo "$GRANTS" | jq '.Grants[].GranteePrincipal' | grep -c "${ACCOUNT}:root") == 0 ]]; then
      aws kms --profile ${PROFILE} --region ${REGION} create-grant --key-id ${CMK_ID} --grantee-principal ${ACCOUNT} --operations DescribeKey Decrypt CreateGrant > /dev/null || tidy_up "Unable to create a KMS grant for the destination account. Aborting."
      # NOTE: could consider retire the grant in tindy up
    else
      echo -e "${COLOR}Grant already exists for target account. ${NC}"
    fi
  else
    tidy_up "Unbale to retrieve the grants information of key ${CMK_ID}"
  fi
}

function check_perms_on_snapshot() {
  # get the key current used to encrypt the snapshot
  KMS_KEY_ARN=$(aws ec2 describe-snapshots --profile ${SRC_PROFILE} --region ${SRC_REGION} --owner-ids ${SRC_ACCT_ID} --snapshot-ids ${SNAPSHOT_ID} --query 'Snapshots[*].KmsKeyId' --output text || tidy_up "Unable to get KMS Key Ids from the snapshots. Aborting.")
  CURRENT_KEY_ID=$(aws kms describe-key --profile ${SRC_PROFILE} --region ${SRC_REGION} --key-id ${KMS_KEY_ARN} --query "KeyMetadata.KeyId" --output text)
  echo -e "${COLOR}KMS key(s) used on source AMI:${NC}" ${CURRENT_KEY_ID}
  if [[ "${SRC_CMK_ID}x" != "x" ]]; then
    # When a CMK is provided, it should be used for copying. 
    if [[ ${SRC_CMK_ID} != ${CURRENT_KEY_ID} ]];then
      # the specified CMK is not as same as current encryption key. Need to re-generate snapshot.
      echo -e "${COLOR}Source CMK ${SRC_CMK_ID} is not used by the AMI. A new snapshot needs to be generated with this CMK. ${NC}"
      return 1
    else 
      echo -e "${COLOR}Source CMK ${SRC_CMK_ID} is currently used by the AMI. ${NC}"
      return 0
    fi
  else 
    # No CMK provided. We will either use current key if it's a CMK or generate a temp one if it's not.
    if [[ "$(aws kms describe-key --profile ${SRC_PROFILE} --region ${SRC_REGION} --key-id ${CURRENT_KEY_ID} --query 'KeyMetadata.KeyManager' --output text)" != "CUSTOMER" ]]; then
      echo -e "${COLOR}Current key ${CURRENT_KEY_ID} is not customer managed. A temporary CMK will be generated. ${NC}"
      SRC_CMK_ID=$(aws kms create-key --profile ${SRC_PROFILE} --region ${SRC_REGION} --description "Temp CMK for AMI copy" --query "KeyMetadata.KeyId" --output text) 
      aws kms create-alias --alias-name alias/temp-cmk-for-copy-$(echo ${SRC_CMK_ID} | awk -F- '{print $1}') --target-key-id ${SRC_CMK_ID} --profile ${SRC_PROFILE} --region ${SRC_REGION} 
      echo -e "${COLOR}Temp CMK generated:${NC} ${SRC_CMK_ID}"
      TEMP_KMS_KEY_CREATED=true
      return 1
    else
      SRC_CMK_ID=${CURRENT_KEY_ID}
      return 0
    fi
  fi
}

function copy_snapshot_to_dest() {
  echo -e "${COLOR}Copying Snapshot to Destination Account-ID${NC} ${DST_ACCT_ID}"

  aws ec2 --profile ${SRC_PROFILE} --region ${SRC_REGION} modify-snapshot-attribute --snapshot-id ${SNAPSHOT_ID} --attribute createVolumePermission --operation-type add --user-ids $DST_ACCT_ID || tidy_up "Unable to add permissions on the snapshots for the destination account. Aborting."
  echo -e "${COLOR}Permission added to Snapshot:${NC} ${SNAPSHOT_ID}"
  DST_SNAPSHOT=$(aws ec2 copy-snapshot --profile ${DST_PROFILE} --region ${DST_REGION} --source-region ${SRC_REGION} --source-snapshot-id ${SNAPSHOT_ID} --description "Copied from ${ORIG_SNAPSHOT_ID} In Account ${SRC_ACCT_ID}" --encrypted ${CMK_OPT} --query SnapshotId --output text|| tidy_up "Unable to copy snapshot. Aborting.")
  echo -e "${COLOR}Destination snapshot is getting created:${NC} ${DST_SNAPSHOT}"

  ## need to wait for the snapshot copy to happen as it can be long time and snapshot-wait takes too long
  wait_for_snapshot_copy ${DST_SNAPSHOT} ${DST_PROFILE} ${DST_REGION}

  $(aws ec2 create-tags --resources ${DST_SNAPSHOT} --tags "${NEW_SNAP_TAGS}" --profile ${DST_PROFILE} --region ${DST_REGION} || tidy_up "Unable to add tags to the Snapshot in the destination account. Aborting." ${DST_SNAPSHOT})
  # Prepares the json data with the new snapshot IDs and remove unecessary information
  echo -e "${COLOR}Snapshots${NC} ${SNAPSHOT_ID} ${COLOR}copied as${NC} ${DST_SNAPSHOT}"
  AMI_DETAILS=$(echo ${AMI_DETAILS} | sed -e s/${ORIG_SNAPSHOT_ID}/${DST_SNAPSHOT}/g )
}


function create_ami_in_dest() {

# Check  EnaSupport status of  Source  AMI 
 ORIG_AMI_ENA_status=$(aws ec2 describe-images --profile ${SRC_PROFILE} --region ${SRC_REGION} --image-id  ${AMI_ID}  | jq -r '.Images[].EnaSupport' || tidy_up "Unable to fetch ENA support details for Original AMI. Aborting.")
# echo -e "${COLOR}ENA support status of orginal AMI of source account is: ${ORIG_AMI_ENA_status}"

# Copy AMI structure while removing read-only / non-idempotent values
NEW_AMI_DETAILS=$(echo ${AMI_DETAILS} | jq --arg v ${AMI_ID} --arg w ${SRC_ACCT_ID} 'del(.. | .Encrypted?) | del(.Tags,.Platform,.ImageId,.CreationDate,.OwnerId,.ImageLocation,.State,.ImageType,.RootDeviceType,.Hypervisor,.Public,.EnaSupport )')


if [[ ${ORIG_AMI_ENA_status} == true ]];then
ENA_SUPPORT="--ena-support"   
else	
ENA_SUPPORT="--no-ena-support"
fi

# Create the AMI in the destination
CREATED_AMI=$(aws ec2 register-image --profile ${DST_PROFILE} --region ${DST_REGION} ${ENA_SUPPORT} --cli-input-json "${NEW_AMI_DETAILS}" --query ImageId --output text || tidy_up "Unable to register AMI in the destination account. Aborting." ${DST_SNAPSHOT})
echo -e "${COLOR}AMI created succesfully in the destination account:${NC} ${CREATED_AMI}"

# Copy Tags
NEW_AMI_TAGS="$(echo ${AMI_DETAILS} | jq -c '.Tags')"
$(aws ec2 create-tags --resources ${CREATED_AMI} --tags "${NEW_AMI_TAGS}" --profile ${DST_PROFILE} --region ${DST_REGION} || tidy_up "Unable to add tags to the AMI in the destination account. Aborting." ${DST_SNAPSHOT} ${CREATED_AMI})
echo -e "${COLOR}Tags added sucessfully${NC}"

}

function set_colours()
{
COLOR='\033[1;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color
}


## tidy_up, requires the following params :
# no params, all ok so just remove the temp snapshot if it exists
# $1 - error message to print out
# $2 - if supplied, the id of the destination snapshot
# $3 - if supplied, the id of the new AMI

function tidy_up()
{
# if param passed in then delete the snapshot whos name matches
# if we had to create a snapshot copy in our SRC area then get rid of it as it isnt required
if [ "${ORIG_SNAPSHOT_ID}" != "${SNAPSHOT_ID}" ]
then
	echo -e "${COLOR}Remove the Temporary Snapshot Created In Source Account As No Longer Needed${NC} ${SNAPSHOT_ID}" >&2
	aws ec2 delete-snapshot --profile ${SRC_PROFILE} --region ${SRC_REGION} --snapshot-id ${SNAPSHOT_ID} || die "Can't Remove the Copied Snapshot ${SNAPSHOT_ID}"
fi

# get rid of dest AMI
if [ "$3" ]
then
	echo -e "${COLOR}Removing the Destination Ami as something went wrong - ${3} {NC} ${1}" >&2
	aws ec2 deregister-image  --profile ${DST_PROFILE} --region ${DST_REGION}  --image-id ${3} || die "Can't Delete the New AMI - $3"
fi

sleep 5

# get rid of the dest Snapshot
if [ "$2" ]
then
	echo -e "${COLOR}Removing the Destination Snapshot${NC} ${2}" >&2
	aws ec2 delete-snapshot --snapshot-id ${2}  --profile ${DST_PROFILE} --region ${DST_REGION} || die "Can't Delete the new snapshot - $2"
fi

# get rid of temp key
if [[ ${TEMP_KMS_KEY_CREATED} == true ]];then
  if aws kms schedule-key-deletion --profile ${SRC_PROFILE} --region ${SRC_REGION} --key-id ${SRC_CMK_ID} --pending-window-in-days 7; then
    echo -e "${COLOR}Scheduled removal of temp CMK${NC} ${SRC_CMK_ID}"
  else
    echo -e "${RED}ERROR: failed to remove temp CMK ${NC} ${SRC_CMK_ID}"
  fi
fi

if [ ! "${1}" ]
then
	echo -e "${COLOR}Copy Has Completed Successfully${NC}"
	exit 0
else
	die "$1"
fi

}

# function to wait for the event passed in as params
function wait_for_snapshot_copy() {
# $1 - The snapshot id
# $2 - aws profile
# $3 - aws region

  #  max 20 mins
  MAX=40 
  SLEEP_TIME=30
  PROGRESS="0%"

  for (( COUNT=1; COUNT < ${MAX}; COUNT++ ))
  do
	echo -e "Waiting for Snapshot $1 copy to complete. ${COLOR} Progress ${PROGRESS} ${NC}"
	if [[ $(aws ec2 describe-snapshots --snapshot-ids ${1} --profile ${2} --region ${3} --query "Snapshots[*].State" --output text || die "Failed to retrieve information about snapshot ${1}") == "error" ]]; then
      tidy_up "Failed to create snapshot ${1}. Aborting."
    else
	  PROGRESS=$(aws ec2 describe-snapshots --snapshot-ids ${1} --profile ${2} --region ${3} --query "Snapshots[*].Progress" --output text || die "Failed to retrieve information about snapshot ${1}")
	  if [ "${PROGRESS}" == "100%" ]; then
		echo -e "${COLOR}Snapshot copy completed: ${NC} $1"
		sleep 10
		# a status check to be certain
	    [[ $(aws ec2 describe-snapshots --snapshot-ids ${1} --profile ${2} --region ${3} --query "Snapshots[*].State" --output text) != "completed" ]] && tidy_up "Failed while waiting the snapshots to be copied. Aborting."
		return 0
      else 
	    sleep ${SLEEP_TIME}
      fi
	fi
  done
  # if we get here then it has failed or timed out
  tidy_up "Failed while waiting the snapshots to be copied. Aborting."
}

######################################################################################################################################################################
#
# End Of Functions
#
######################################################################################################################################################################



######################################################################################################################################################################
#
# MAIN
#
######################################################################################################################################################################


# Checking dependencies
command -v jq >/dev/null 2>&1 || die "jq is required but not installed. Aborting. See https://stedolan.github.io/jq/download/"
command -v aws >/dev/null 2>&1 || die "aws cli is required but not installed. Aborting. See https://docs.aws.amazon.com/cli/latest/userguide/installing.html"


while getopts ":p:P:r:R:a:k:K:h" opt; do
    case $opt in
        h) usage && exit 1
        ;;
        p) SRC_PROFILE="$OPTARG"
        ;;
        P) DST_PROFILE="$OPTARG"
        ;;
        r) SRC_REGION="$OPTARG"
        ;;
        R) DST_REGION="$OPTARG"
        ;;
        a) AMI_ID="$OPTARG"
        ;;
        k) SRC_CMK_ID="$OPTARG"
        ;;
        K) DST_CMK_ID="$OPTARG"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2 
            usage && exit 1
        ;;
    esac
done

set_colours

validate_params

retrieve_source_ami_snapshot

if [[ ${SRC_PROFILE} != ${DST_PROFILE} ]]; then
  # if we havent got perms on the snapshot then create a new one and apply our key and then use our new snapshot thereafter
  if ! check_perms_on_snapshot
  then

      # get the new snapshot id and overwrite the var and now go back to check_perms_on_snapshot
      SNAPSHOT_ID=$(aws ec2 copy-snapshot --profile ${SRC_PROFILE} --region ${SRC_REGION} --source-region ${SRC_REGION} --source-snapshot-id  ${SNAPSHOT_ID} --encrypted --kms-key-id ${SRC_CMK_ID} --description "Copy from original snapshot ${SNAPSHOT_ID} with new CMK" --query "SnapshotId" --output text || die "Unable to make a copy of the original snapshot with key ${SRC_CMK_ID}")

      ## need to wait for the snapshot copy to happen as it can be long time and snapshot-wait takes too long
      wait_for_snapshot_copy ${SNAPSHOT_ID} ${SRC_PROFILE} ${SRC_REGION}

      echo -e "${COLOR}Calling check_perms_on_snapshot again with our new snapshot${NC} ${SNAPSHOT_ID}"
      if ! check_perms_on_snapshot
      then
		die "The new snapshot still doesn't have a valid CMK. Abort."
      fi
  fi
  create_cmk_grant ${SRC_PROFILE} ${SRC_REGION} ${DST_ACCT_ID} ${SRC_CMK_ID}
fi

copy_snapshot_to_dest

create_ami_in_dest

tidy_up
