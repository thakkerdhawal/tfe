#!/bin/bash
set -e

# Initialization

FROM=
TEMP=/tmp
VERBOSE=${VERBOSE:-false}
REGIONS="eu-west-2 eu-west-1"

function usage() {
echo '
This is a wraper script for applying changes to all Terraform components in an AWS account. 

  Usage:' "$0" '-A <aws_account> -p <profile> -e <env> -a <action> [-c <cred_file>] [-v <vars>] [-o <true|false>] [-V] [-h]
    -A|--account: (Required) [shared-services|core]
    -p|--profile: (Required) AWS Profile
    -e|--env|--environment: (Required) target environment, i.e [lab|cicd|nonprod|prod]
    -a|--action: (Required) Supported actions are:
         plan: plan only.
         apply: plan and apply
    -r|--region: (Optional, default to both eu-west-1 and eu-west-2) target region, i.e [eu-west-1|eu-west-2]
    -f|--from: (Optional, default to empty) The component to start from.
    -v|--vars: (Optional, default to empty) Extra vars for Terraform. 
    -c|--cred_file (Optional, default to ~/.aws/credentials): AWS credential file
    -o|--autoapprove: (Optional, default to false) Process without prompt before apply or destroy. [true|false]
    -h|--help: display this message
    -V|--verbose: display DEBUG messages

  Example:
        ' "$0" ' --account shared-services --profile nwmss_test --env lab --action plan --region eu-west-2
        ' "$0" ' -A shared-services -p nwmss_test -e lab -a apply
        ' "$0" ' -A core -p nwm_nonprod -e nonprod -a apply -f networks 
        ' "$0" ' -A shared-services -p nwmss_test -e lab -a apply -c ~/.aws/my_cred -v 'ssh_private_key=PATH_TO_KEY'
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

#
# Process input
#

# cd "$(dirname ${BASH_SOURCE[0]})"
if ! OPTS=`getopt -o A:f:p:e:a:r:c:v:o:Vh --long account:,profile:,env:,environment:,action:,region:,from:,cred_file:,vars:,autoapprove:,help,verbose -- "$@"`; then
  usage
  logging ERROR "failed to parse inputs"
fi

# extract options and their arguments into variables.
eval set -- "$OPTS"
while true
do
  case "$1" in
    -A|--account)
      ACCOUNT=$2; shift 2 ;;
    -f|--from)
      FROM=$2; shift 2 ;;
    -r|--region)
      REGIONS=$2; shift 2 ;;
    -a|--action)
      ACTION=$2; KEY=$1 ; VALUE=$2 ; shift 2 ; set -- "$@" "$KEY" "$VALUE" ;;
    -p|--profile)
      PROFILE=$2; KEY=$1 ; VALUE=$2 ; shift 2 ; set -- "$@" "$KEY" "$VALUE" ;;
    -e|--env|--environment)
      ENV=$2; KEY=$1 ; VALUE=$2 ; shift 2 ; set -- "$@" "$KEY" "$VALUE" ;;
    -[cvo]|--cred_file|--vars|--autoapprove)
      KEY=$1 ; VALUE=$2 ; shift 2 ; set -- "$@" "$KEY" "$VALUE" ;;
    -V|--verbose) VERBOSE=true ; shift ; set -- "$@" "-V" ;;
    -h|--help) usage; exit 0 ;;
    --) shift ; break ;;
    *) usage; logging ERROR "Unknown input." ;;
  esac
done

# Input Validation
[[ "${ENV}x" == "x" || "${PROFILE}x" == "x" || "${ACCOUNT}x" == "x" || "${ACTION}x" == "x" ]] && { usage; logging ERROR "Missing required inputs"; }
[[ $ACCOUNT == "shared-services" || $ACCOUNT == "core" ]] || { usage; logging ERROR "Invalid AWS Acount: $ACCOUNT"; }
[[ $ACTION == "apply" || $ACCOUNT == "plan" ]] || { usage; logging ERROR "The supported actions are: apply, plan"; }

# Main
SCRIPT_DIR=$(dirname $(realpath $0))
for COMPONENT in $(cat ${SCRIPT_DIR}/../terraform/$ACCOUNT/release); do
  if [[ ! -z $FROM ]]; then
    [[ $COMPONENT != $FROM ]] && { logging INFO "######## Skipping component: $COMPONENT ########" ; continue; } || FROM=
  fi
  logging INFO "######## Releasing component: $COMPONENT ########"
  for REGION in $REGIONS; do
    ${SCRIPT_DIR}/tf_wrapper.sh $@ -r $REGION -d ${SCRIPT_DIR}/../terraform/$ACCOUNT/$COMPONENT
  done
done


