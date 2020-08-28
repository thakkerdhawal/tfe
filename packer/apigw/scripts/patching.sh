#!/bin/bash
# Initialization

set -e

# Region is hardcoded as there is little benefit of making the patch bucket HA
S3ENDPOINT=https://s3-eu-west-1.amazonaws.com
PATCHING_CLI=/opt/SecureSpan/Appliance/libexec/patchcli_launch
TEMP=/var/tmp
NOREBOOT=false
CURL_FTP='/usr/bin/curl --user anonymous@ftp.ca.com:guest@ca.com'


function usage() {
echo '
  Usage:' "$0" '--patch <patch> --bucket <bucket> [--verbos] [--help]
    -p|--patch: Required. The filename of the patch to be installed
    -b|--bucket: Required. S3 bucket where the patch is stored
    -n|--noreboot: Do not reboot after installing a patch (only use this for testing).
    -h|--help: Display this message
    -v|--verbose: display DEBUG messages

  Example:

' "$0" '--patch CA_API_PlatformUpdate_64bit_v9.X-RHEL-2018-07-24.L7P --bucket des-ca-apigw-patches --verbose 
' "$0" '--patch NONE 
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

function download_from_s3 () {
  [[ ! -z $1 ]] && logging DEBUG "Pulling S3 object: $1" || logging ERROR "Please provide the S3 object to download"
  instance_profile=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/) || logging ERROR "Failed to find IAM profile attached to the instance."
  aws_access_key_id=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${instance_profile} | grep AccessKeyId | awk -F \" '{print $4}') || logging ERROR "Failed to get AWS Access key"
  aws_secret_access_key=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${instance_profile} | grep SecretAccessKey | awk -F \" '{print $4}') || logging ERROR "Failed to get AWS Secret Access key"
  token=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${instance_profile} | grep Token | awk -F \" '{print $4}') || logging ERROR "Failed to get AWS token"
  date=$(date +'%a, %d %b %Y %H:%M:%S %z')
  signature=$(/bin/echo -en "GET\n\n\n${date}\nx-amz-security-token:${token}\n/${1}" | openssl sha1 -hmac ${aws_secret_access_key} -binary | base64)
  authorization="AWS ${aws_access_key_id}:${signature}"
  if curl -Ok -H "Date: ${date}" -H "X-AMZ-Security-Token: ${token}" -H "Authorization: ${authorization}" ${S3ENDPOINT}/${1}; then
    logging DEBUG "File downloaded from S3"
  else
    logging ERROR "Failed to download S3 object: ${S3ENDPOINT}/${1}"
  fi
}

#
# Process input
#

cd "$(dirname ${BASH_SOURCE[0]})"
OPTS=`getopt -o p:b:nvh --long patch:,bucket:,noreboot,help,verbose -- "$@"`

if [ $? != 0 ] ; then
  usage
  logging ERROR "failed to parse inputs"
fi

# extract options and their arguments into variables.
eval set -- "$OPTS"
while true
do
  case "$1" in
    -p|--patch)
      PATCH=$2 ; shift 2 ;;
    -b|--bucket)
      S3BUCKET=$2 ; shift 2 ;;
    -n|--noreboot) NOREBOOT=true ; shift ;;
    -v|--verbose) VERBOSE=true ; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift ; break ;;
    *)
      usage
      logging ERROR "Unknown input."
      exit 1 ;;
  esac
done

[[ ${PATCH} == "NONE" || ${PATCH} == "none" ]] && { logging INFO "No patch needs to be installed."; exit 0; }
[[ -z ${PATCH} || -z ${S3BUCKET} ]] && { usage; logging ERROR "Missing input"; }

# Patching
cd /home/layer7
logging INFO "Start downloading patch to /home/layer7."
download_from_s3 "${S3BUCKET}/${PATCH}" && logging INFO "Patch downloaded." || logging ERROR "Failed to download patch file: ${S3ENDPOINT}/${S3BUCKET}/${PATCH}"
chown layer7: /home/layer7/${PATCH}
sleep 15s && logging INFO "Start uploading patch to Gateway."
sudo -u layer7 $PATCHING_CLI upload /home/layer7/${PATCH} && logging INFO "Patch uploaded." || logging ERROR "Failed to upload patch ${PATCH}"
sleep 15s && logging INFO "Start installing patch"
sudo -u layer7 $PATCHING_CLI install ${PATCH%.*} autodelete true && logging INFO "Patch installed." || logging ERROR "Failed to install patch ${PATCH%.*}"

# cleanup
rm -f /home/layer7/${PATCH} && logging INFO "Patch file deleted." || logging ERROR "Failed to delete the downloaded patch file."

# reboot after each patch installation
[[ ${NOREBOOT} == false ]] && { logging INFO "The Gateway will be rebooted now ..."; /sbin/reboot; } || logging INFO "No reboot requeste, exit now"
