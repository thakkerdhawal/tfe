#!/bin/bash

srcfiles=/ecomm/caplin/liberator/stream-agilemarkets/current/var/packet-rttpd.log.20*
account_alias[724329805838]=nwmtest
account_alias[106756092552]=nwmnonprod
account_alias[128363688939]=nwmprod

function logging () {
  if [[ $VERBOSE == true || ! "$1" == DEBUG ]]; then
    echo "`/bin/date +%F-%T` $*" 
    /usr/bin/logger -p local0.notice -t $(basename $0) "$*"
  fi

  if [[ "$1" == ERROR ]]; then
    exit 1
  fi
}

#
#

# Get variables form Metadata
region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//') || logging ERROR "Failed to find Region from metadata."
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id) || logging ERROR "Failed to find instance ID."
instance_profile=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/) || logging ERROR "Failed to find IAM profile attached to the instance."
aws_access_key_id=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${instance_profile} | grep AccessKeyId | awk -F \" '{print $4}') || logging ERROR "Failed to get AWS Access key"
export AWS_SECRET_ACCESS_KEY=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${instance_profile} | grep SecretAccessKey | awk -F \" '{print $4}') || logging ERROR "Failed to get AWS Secret Access key"
export AWS_SECURITY_TOKEN=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${instance_profile} | grep Token | awk -F \" '{print $4}') || logging ERROR "Failed to get AWS token"
account_number=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '(?<="accountId" : ")[^"]*(?=")')

dstpath=/${instance_id}
bucket=logging-${account_alias[$account_number]}-stream-binary-${region}

for srcfile in ${srcfiles}
do
  # Gzip file if not already gziped
  if [ ${srcfile: -3} != ".gz" ]
  then
    logging INFO "Gzipping ${srcfile}"
    gzip -9 ${srcfile}
    srcfile=${srcfile}.gz
  fi
  # Upload to S3
  logging INFO "Uploading ${srcfile}"
  $(dirname $0)/s3-bash4/bin/s3-put -r $region -k $aws_access_key_id -T ${srcfile} -C GLACIER /${bucket}${dstpath}/$(basename $srcfile | tr ':' '_')
  if [ $? -eq 0 ]
  then
    logging INFO "Successful upload. Removing file ${srcfile}"
    rm ${srcfile}
  else
    logging ERROR "Failed upload of ${srcfile}"
  fi
done

