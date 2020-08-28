#!/bin/bash
set -e

# Initialization

PLUGINS=/usr/local/bin/.terraform/plugins/linux_amd64
TEMP=/tmp
DIR=$(pwd)
PROFILE=
REGION=
ACTION=
EXTRA_VARS=
AUTOAPPROVE=${AUTOAPPROVE:-false}
TF_AUTOAPPROVE=
VERBOSE=${VERBOSE:-false}
CRED=~/.aws/credentials
CONSUL_URL=https://ecomm.fm.rbsgrp.net

function usage() {
echo '
  Usage:' "$0" '-d <directory> -p <profile> -r <region> -a <action> [-c <cred_file>] [-o <true|false>] [-V] [-h]
    -p|--profile: (Required) AWS Profile
    -r|--region: (Required) AWS region [eu-west-1|eu-west-2|us-east-1]
    -e|--env|--environment: (Required) target environment, i.e [lab|cicd|nonprod|prod]
    -a|--action: (Required) Supported actions are:
         plan: plan only.
         apply: plan and apply
         destroy: destroy straightaway
         apply_and_destroy: plan, apply and then destroy
         refresh: detect drift and update state 
         state|taint|untaint <arg>: run standard Terraform command. See examples below.
    -d|--dir|--directory: (Optional, default to current directory) directory of terraform templates.
    -v|--vars: (Optional, default to empty) Extra vars for Terraform. 
    -c|--cred_file (Optional, default to ~/.aws/credentials): AWS credential file
    -o|--autoapprove: (Optional, default to false) Process without prompt before apply or destroy. [true|false]
    -h|--help: display this message
    -V|--verbose: display DEBUG messages

  Example:
        ' "$0" ' --env lab --profile nwmss_test --region eu-west-2 --action plan 
        ' "$0" ' -e lab -p nwm_test -r eu-west-2 -a apply -v 'aws_profile_ss=nwmss_test' -o true -V
        ' "$0" ' -d TARGET_DIR -e nonprod -p nwm_nonprod -r eu-west-2 -a destroy -c PATH_TO_CRED -v 'ssh_private_key=PATH_TO_KEY'
        ' "$0" ' -d TARGET_DIR -e nonprod -p nwm_nonprod -r eu-west-2 -a 'destroy -target=aws_lb_target_group.tg-fxmp-uk'
        ' "$0" ' -d TARGET_DIR -e nonprod -p nwm_nonprod -r eu-west-2 -a "state list"
        ' "$0" ' -d TARGET_DIR -e nonprod -p nwm_nonprod -r eu-west-2 -a "state show aws_instance.apache[0]"
        ' "$0" ' -d TARGET_DIR -e nonprod -p nwm_nonprod -r eu-west-2 -a "taint aws_instance.apache.0"
'
}

function logging () {
  [[ -z $LOGFILE ]] && { LOGFILE=$(mktemp $TEMP/$(basename $0)-log.XXXX) ; logging INFO "Creating log file $LOGFILE"; }
  if [[ $VERBOSE == true || ! "$1" == DEBUG ]]; then
    echo "`/bin/date +%F-%T` $*" | tee -a $LOGFILE
  fi

  if [[ "$1" == ERROR ]]; then
    exit 1
  fi
}
# TODO: check binary
function check_required_binary () {
  logging INFO "OK"
}

function parse_dir() {
  logging DEBUG "Validating target Terraform template directory..."
  local DIR=$(realpath ${1})
  COMPONENT=$(basename ${DIR})
  ACCOUNT=$(basename $(dirname ${DIR}))
  [[ -z ${ACCOUNT} || -z ${COMPONENT} ]] && logging ERROR "Cannot determine target component and AWS account." || logging INFO "Target Component: ${COMPONENT} in AWS account ${ACCOUNT}"
}

function parse_vars() {
  logging DEBUG "Parsing extra Terraform variables"
  for i in $@; do
    EXTRA_VARS="${EXTRA_VARS} -var '$i'"
  done
  # TODO: validate syntax?
}

function validate_consul_token () {
  logging DEBUG "Validating consul token ${CONSUL_HTTP_TOKEN}..."
  [[ -z ${CONSUL_HTTP_TOKEN} ]] && logging ERROR "Cannot find Consul token in CONSUL_HTTP_TOKEN."
  ACL=$(curl -sk --url ${CONSUL_URL}/v1/acl/info/${CONSUL_HTTP_TOKEN} | jq .[].Rules)
  echo -e "$ACL" | grep "key.*application/nwm/${ENV}/terraform/${ACCOUNT}/.*policy.*write" > /dev/null 2>&1 || logging ERROR "Invalid Consul TOKEN: ${CONSUL_HTTP_TOKEN} for key application/nwm/${ENV}/terraform/${ACCOUNT}"
}

function validate_aws_profile () {
  logging DEBUG "Validating AWS profile ..."
  [[ -r $CRED ]] || { usage; logging ERROR "Cannot read AWS credential: $CRED"; }
  if VALIDATION=$(AWS_SHARED_CREDENTIALS_FILE=${CRED} aws --profile ${PROFILE} --region ${REGION} sts get-caller-identity --query 'Arn' 2>/dev/null); then 
    logging DEBUG "AWS profile ${PROFILE} is valid."
    # Only refresh token if its using adfs
    echo $VALIDATION | grep "assumed-role.*ADFS" >/dev/null 2>&1 && $(dirname "$(readlink -f "${0}")")/auth_adfs.sh -p ${PROFILE} || logging DEBUG "AWS profile ${PROFILE} is not using ADFS"
  else
    usage
    logging ERROR "Failed to validate profile ${PROFILE} in ${CRED}." 
  fi
}

function tf_init () {
  local DIR=${1}
  validate_consul_token
  cd ${DIR}
  # Need this, so that tf init does not carry forward current workspace in to new environment (when Changing ENV i.e. lab to cicd).
  [[ -r ./.terraform/terraform.tfstate ]] && terraform workspace select default
  logging INFO "Initialise Terraform environment"
  [[ -r ./.terraform/terraform.tfstate ]] && rm -vf ./.terraform/terraform.tfstate
  if [[ $VERBOSE == true ]];then 
    terraform init -backend-config="path=application/nwm/${ENV}/terraform/${ACCOUNT}/state/tfstate" -plugin-dir=${PLUGINS} 
  else 
    terraform init -backend-config="path=application/nwm/${ENV}/terraform/${ACCOUNT}/state/tfstate" -plugin-dir=${PLUGINS} > /dev/null
  fi
  # set TF workspace
  if terraform workspace list | grep -w "${ENV}_${ACCOUNT}_${COMPONENT}_${REGION}" > /dev/null 2>&1; then
    logging INFO "Setting Terraform workspace to ${ENV}_${ACCOUNT}_${COMPONENT}_${REGION}"
    terraform workspace select ${ENV}_${ACCOUNT}_${COMPONENT}_${REGION}
  else
    logging INFO "Creating new Terraform workspace ${ENV}_${ACCOUNT}_${COMPONENT}_${REGION}"
    terraform workspace new ${ENV}_${ACCOUNT}_${COMPONENT}_${REGION}
  fi
}

function tf_plan () {
  tf_init ${1}
  logging DEBUG "Running Terraform Plan."
  eval "terraform plan -var "aws_profile=${PROFILE}" -var "credential_file=${CRED}" ${EXTRA_VARS}" # -out /tmp/tf-build.$(terraform workspace show).$(whoami).tfplan
}

function tf_apply () {
  tf_init ${1}
  logging DEBUG "Running Terraform Apply"
  eval "terraform apply -var "aws_profile=${PROFILE}" -var "credential_file=${CRED}" ${EXTRA_VARS} $TF_AUTOAPPROVE"
  # terraform apply /tmp/tf-build.$(terraform workspace show).$(whoami).tfplan
}

function tf_destroy () {
  tf_init ${1}
  if [[ $(terraform state list | wc -l) == 0 ]]; then
    logging INFO "Abort. Nothing to destroy."
  else 
    logging DEBUG "Running Terraform Destroy"
    eval "terraform ${@:2} -var "aws_profile=${PROFILE}" -var "credential_file=${CRED}" ${EXTRA_VARS} $TF_AUTOAPPROVE"
  fi
}

function tf_refresh () {
  tf_init ${1}
  logging DEBUG "Running Terraform Refresh"
  eval "terraform refresh -var "aws_profile=${PROFILE}" -var "credential_file=${CRED}" ${EXTRA_VARS}"
}

function tf_cmd () {
  tf_init ${1}
  logging DEBUG "Running Terraform ${@:2}"
  terraform ${@:2}
}

#
# Process input
#

# cd "$(dirname ${BASH_SOURCE[0]})"
if ! OPTS=`getopt -o d:p:r:e:a:c:v:o:Vh --long dir:,directory:,profile:,region:,env:,environment:,action:,cred_file:,vars:,autoapprove:,help,verbose -- "$@"`; then
  usage
  logging ERROR "failed to parse inputs"
fi

# extract options and their arguments into variables.
eval set -- "$OPTS"
while true
do
  case "$1" in
    -d|--dir|--directory)
      DIR=$2; shift 2 ;;
    -p|--profile)
      PROFILE=$2 ; shift 2 ;;
    -r|--region)
      REGION=$2 ; shift 2 ;;
    -a|--action)
      ACTION=$2 ; shift 2 ;;
    -e|--env|--environment)
      ENV=$2 ; shift 2 ;;
    -c|--cred_file)
      CRED=$2 ; shift 2 ;;
    -v|--vars)
      parse_vars $2; shift 2 ;;
    -o|--autoapprove) 
      AUTOAPPROVE=$2; shift 2 ;;
    -V|--verbose) VERBOSE=true ; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift ; break ;;
    *)
      usage; logging ERROR "Unknown input." ;;
  esac
done

# Input Validation
[[ "${ENV}x" == "x" || "${PROFILE}x" == "x" || "${REGION}x" == "x" || "${ACTION}x" == "x" ]] && { usage; logging ERROR "Missing required inputs"; }
[[ $ENV == "lab" || $ENV == "cicd" || $ENV == "nonprod" || $ENV == "prod"  ]] || { usage; logging ERROR "Invalid target environment: $ENV"; }
[[ $REGION == "eu-west-1" || $REGION == "eu-west-2" || $REGION == "us-east-1" ]] || { usage; logging ERROR "Invalid AWS region: $REGION"; }
[[ -d $DIR ]] && parse_dir ${DIR} || { usage; logging ERROR "Invalid directory: $DIR"; }
validate_aws_profile 
[[ ${AUTOAPPROVE} == true ]] && TF_AUTOAPPROVE="-auto-approve"  

# Main
case $ACTION in
  plan)
    tf_plan ${DIR} ;;
  apply)
    tf_apply ${DIR} ;;
  destroy|destroy\ *)
    tf_destroy ${DIR} ${ACTION};;
  apply_and_destroy)
    tf_apply ${DIR}; tf_destroy ${DIR} ;;
  refresh)
    tf_refresh ${DIR} ${ACTION} ;;
  state\ *|taint\ *|untaint\ *)
    tf_cmd ${DIR} ${ACTION} ;;
  *)
    usage; logging ERROR "Unknown action: $ACTION." ;;
esac

