#!/bin/bash
# Initialization

VERBOSE=false
CREATENEW=false
KEEPPACKAGE=false
S3BUCKET=
SOURCE=
PROFILE=
REGION="eu-west-1"
AWSCLI=$(which aws)
# TODO: change to prod proxy
FTP_PROXY=lonbp00011.fm.rbsgrp.net 
FTP_USER='anonymous@ftp.ca.com:guest@ca.com'
CURL_FTP='/usr/bin/curl --user anonymous@ftp.ca.com:guest@ca.com'

# Functions
function usage() {
echo '
  Usage:' "$0" '--source <patch file source url> --bucket <bucket> --profile <aws profile name> [--region <aws region>] [--awscli <aws cli>] [--tempdir <temp directory>] [--new] [--verbose [--help] [--keeppackage]
    -s|--source: Required. Source URL of the patch file from CA FTP (ftp://ftp.ca.com/)
    -b|--bucket: Required. Target S3 bucket for storing patches.
    -p|--profile: Required. AWS profile name in ~/.aws/credential
    -r|--region: Optional. AWS region of the S3 bucket. Default to eu-west-1
    -a|--awscli: Optional. Target S3 endpoint of the bucket. Default to $(which aws)
    -t|--tempdir: Optional. The temporary directory used for files in transit. 4GB freespace is recommended. Default to /var/tmp.
    -n|--new: Optional. Create new bucket if target bucket does not exist. Default behavior is abort.
    -k|--keeppackage: Optional. Keep the downloaded file. Default is to delete. 
    -h|--help: display this message
    -v|--verbose: display DEBUG messages

  Example:

' "$0" '\
    --source ftp://ftp.ca.com/pub/API_Management/Gateway/Platform_Patch/v9.x/CA_API_PlatformUpdate_64bit_v9.X-RHEL-2018-07-24.L7P \
    --bucket des-ca-apigw-patches \
    --profile des_ss_sandbox \
    --region eu-west-1 \
    --tempdir /var/tmp \
    --new \
    --verbose
'
}

function logging () {
  [[ -z $LOGFILE ]] && { LOGFILE=$(mktemp /tmp/$(basename $0)-log.XXXX) ; logging INFO "Creating log file $LOGFILE"; }
  if [[ $VERBOSE == true || ! "$1" == DEBUG ]]; then
    echo "`/bin/date +%F-%T` $*" | tee -a $LOGFILE
  fi

  if [[ "$1" == ERROR ]]; then
    exit 1
  fi
}

function ftp_download () {
  # download src_url dst_dir
  FILE_SIZE=$(${CURL_FTP} -skI ${1} | grep Content-Length | awk '{print $2}' | tr -d "\r")
  [[ $? == 0 && $FILE_SIZE =~ ^[0-9]+$ ]] || logging ERROR "Failed to retrieve the package"
  logging DEBUG "Package size in bytes: $FILE_SIZE"
  FREE_SPACE=$(df -B1 ${2} | grep -v Available | awk '{print $4}')
  logging DEBUG "Available diskspace in bytes: $FREE_SPACE"
  [[ $FILE_SIZE -gt $FREE_SPACE ]] && logging ERROR "Not enough freespace in ${2}: $FILE_SIZE > $FREE_SPACE"
  logging DEBUG "Start downloading ..."
  ${CURL_FTP} -C- ${1} -o ${2}/$(basename ${1})
  [[ $? != 0 ]] && logging ERROR "Failed to download package ${1}" || logging INFO "Package downloaded."
}

function extract_patch () {
  # extract_patch src_package dst_dir
  FILE_SIZE=$(unzip -l ${1} | grep "\.L7P$" | awk '{sum += $1} END {print sum}')
  [[ $? == 0 && $FILE_SIZE =~ ^[0-9]+$ ]] || logging ERROR "Failed to calculate patch file size."
  FREE_SPACE=$(df -B1 ${2} | grep -v Available | awk '{print $4}')
  logging DEBUG "Available diskspace in bytes: $FREE_SPACE"
  [[ $FILE_SIZE -gt $FREE_SPACE ]] && logging ERROR "Not enough freespace in ${2}: $FILE_SIZE > $FREE_SPACE"
  logging DEBUG "Start unpacking ..."
  unzip -jq ${1} *.L7P -d ${2}
  [[ $? != 0 ]] && logging ERROR "Failed to extract patch file from ${1}." || logging INFO "Patch file extracted."
}

function cleanup () {
  rm -rf ${TEMP}
}

#
# Process input
#

cd "$(dirname ${BASH_SOURCE[0]})"
OPTS=`getopt -o s:b:p:r:a:t:nkvh --long source:,bucket:,profile:,region:,awscli:,tempdir:,new,keeppackage,help,verbose -- "$@"`

if [ $? != 0 ] ; then
  usage
  logging ERROR "Failed to parse inputs"
fi

# extract options and their arguments into variables.
eval set -- "$OPTS"
while true
do
  case "$1" in
    -s|--source)
      SOURCE=$2 ; shift 2 ;;
    -b|--bucket)
      S3BUCKET=$2 ; shift 2 ;;
    -p|--profile)
      PROFILE=$2 ; shift 2 ;;
    -r|--region)
      REGION=$2 ; shift 2 ;;
    -a|--awscli)
      AWSCLI=$2 ; shift 2 ;;
    -t|--tempdir)
      TEMPDIR=$(mktemp -dp $2) ; shift 2 ;;
    -n|--new) CREATENEW=true ; shift ;;
    -v|--verbose) VERBOSE=true ; shift ;;
    -k|--keeppackage) KEEPPACKAGE=true ; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift ; break ;;
    *)
      usage
      logging ERROR "Unknown input."
      exit 1 ;;
  esac
done

# Input validation
[[ -z ${SOURCE} || -z ${S3BUCKET} ]] && { usage; logging ERROR "Missing input"; }
SOURCE_PROXY=${SOURCE/ftp.ca.com/${FTP_PROXY}}
[[ -x ${AWSCLI} ]] || logging ERROR "cannot find executable AWS CLI"
CRED="--profile ${PROFILE} --region ${REGION}"
logging DEBUG "checking patch file source url..."
TEMP=${TEMPDIR:-$(mktemp -dp /var/tmp)}

if ${CURL_FTP} -sI ${SOURCE_PROXY} >/dev/null 2>&1
then
  logging DEBUG "patch file source url accessible."
else
  logging ERROR "cannot access patch file url ${SOURCE}. Please verify."
fi

logging DEBUG "checking AWS credential of the given profile ..."
if ${AWSCLI} sts get-caller-identity ${CRED} > /dev/null 
then
  logging DEBUG "AWS credential verified."
else
  logging ERROR "Failed to authenticate AWS profile ${PROFILE} in ${REGION}."
fi

# Check S3 bucket
logging DEBUG "checking target S3 bucket ..."
if ${AWSCLI} s3api head-bucket --bucket ${S3BUCKET} ${CRED} >/dev/null 2>&1
then
  logging DEBUG "target S3 bucket found." 
else
  logging INFO "the target bucket does not exist."
  [[ $CREATENEW != true ]] && logging ERROR "Aborted: target bucket does not exist. Please add -n/--new flag if you wish it to be created."
  if ${AWSCLI} s3api create-bucket --bucket ${S3BUCKET} --create-bucket-configuration LocationConstraint=${REGION} --acl private ${CRED} > /dev/null
  then
    logging INFO "bucket ${S3BUCKET} created in ${REGION}."
  else
    logging ERROR "failed to create bucket ${S3BUCKET} in ${REGION}."
  fi
fi

# Download patch
logging INFO "Download ${SOURCE} to ${TEMP} ..."
ftp_download ${SOURCE_PROXY} ${TEMP}

# Extract software patch
if [[ ${SOURCE} =~ \.zip$ ]]; then
  logging INFO "Need to extract patch files from package."
  extract_patch ${TEMP}/$(basename ${SOURCE}) ${TEMP}
fi

# Upload patch
logging INFO "Uploading patch to S3 bucket."
${AWSCLI} s3 sync $TEMP s3://${S3BUCKET} --exclude '*' --include '*.L7P' ${CRED} 
[[ $? != 0 ]] && logging ERROR "Failed to upload patch to S3 bucket ${S3BUCKET}" || logging INFO "Upload completed."

# clean up
if [[ $KEEPPACKAGE == true ]]; then
  logging INFO "Keeping the downloaded files in ${TEMP}"
else
  logging INFO "Removing all in transit files."
  cleanup
fi

logging INFO "Completed."
