#!/bin/bash

readonly TEMP=/tmp
readonly AWS_CRED_FILE=~/.aws/credentials
readonly S2A_CONF=~/.saml2aws

function logging () {
  [[ -z $LOGFILE ]] && { LOGFILE=$(mktemp $TEMP/$(basename $0)-log.XXXX) ; logging INFO "Creating log file $LOGFILE"; }
  if [[ $VERBOSE == true || ! "$1" == DEBUG ]]; then
    echo "`/bin/date +%F-%T` $*" | tee -a $LOGFILE
  fi

  if [[ "$1" == ERROR ]]; then
    exit 1
  fi
}

function usage() {
echo '
  Usage:' "$0" '-p <profile> [-r <role> -t <threshold>]
    -p|--profile: target aws profile. Required.
    -r|--role: the AWS role to assume. Default is ADFS-PowerUsers
    -t|--threhold: how many seconds the token needs to be valid before refresh. Default is 1200.
    -d|--domain: the AD domain (europa or fm) of your racfid. Default is europa.
    -h|--help: print this message

  Example:
        ' "$0" '-p nwm_lab 
        ' "$0" '-p nwm_lab -r ADFS-ReadOnly -t 600
'
}

function validate_s2a_profile() {
  local target_profile
  local target_domain
  logging INFO "Looking for ${AWS_PROFILE} in saml2aws configure ..."
  [[ -r ${S2A_CONF} ]] && target_profile=$(sed -n "/^\[${AWS_PROFILE}\]/,/^aws_profile/ s/^aws_profile\s*=\s*\(.*\)/\1/p"  ${S2A_CONF})
  if [[ ${target_profile} != ${AWS_PROFILE} ]]; then
    logging WARN "No valid matching profile found."
    return 1
  else
    target_domain=$(sed -n "/^\[${AWS_PROFILE}\]/,/^username/ s/^username\s*=\s*\(.*\)\\\.*/\1/p" ${S2A_CONF})
    if [[ "x${DOMAIN}" != "x" && ${target_domain} != ${DOMAIN} ]]; then
      logging WARN "Changing user racfid domain from ${target_domain} to ${DOMAIN}"
      sed -i "/^\[${AWS_PROFILE}\]/,/^username/ s/\(^username\s*=\s*\)\(.*\)\(\\\.*\)/\1${DOMAIN}\3/g"  ${S2A_CONF}
    fi
    ACC_NUM=$(sed -n "/^\[${AWS_PROFILE}\]/,/^role_arn/ s/^role_arn.*arn:aws:iam::\(.*\):role.*/\1/p" ${S2A_CONF})
    return 0
  fi
}

function setup_s2a_profile() {
  [[ "x${DOMAIN}" == "x" ]] && DOMAIN=europa
  read -p $'\e[96mPlease provide the target account number (https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/AWS+SOP%3A+Access+Model+-+DEng+Support+using+ADFS): \e[0m' ACC_NUM
  [[ $ACC_NUM =~ [0-9]{12} ]] || logging ERROR "Invalid AWS account number. Example: 123456789123"
  saml2aws configure --skip-verify \
                   --skip-prompt \
                   --idp-provider ADFS \
                   --mfa Auto \
                   --url https://sts.rbs.co.uk/adfs/ls/idpinitiatedsignon.aspx \
                   --idp-account ${AWS_PROFILE} \
                   --username "${DOMAIN}\\$(whoami)" \
                   --role="arn:aws:iam::${ACC_NUM}:role/${ROLE}"
  # current version of saml2aws has a hardcoded aws_profile name, so we need to change it manually.
  sed -i "/^\[${AWS_PROFILE}\]/,/^aws_profile/ s/\(^aws_profile\s*=\s*\).*/\1${AWS_PROFILE}/g" ${S2A_CONF}
}

function update_role_mapping () {
  current_role=$(sed -n "/^\[${AWS_PROFILE}\]/,/^role_arn/ s/^role_arn.*:role\/\(.*\)/\1/p" ${S2A_CONF})
  logging INFO "This profile is currently mapped to role '${current_role}'."
  if [[ "x${ROLE}" != "x" && ${current_role} != ${ROLE} ]]; then
    sed -i "/^\[${AWS_PROFILE}\]/,/^role_arn/ s/\(^role_arn.*:role\/\).*/\1${ROLE}/g" ${S2A_CONF}
    logging INFO "The AWS role this profile mapped to has been changed to ${ROLE}"
  else
    ROLE=${current_role}
  fi
}

function validate_aws_token() {
  logging INFO "Validating AWS Security Token for ${AWS_PROFILE} ..."
  [[ ! -r ${AWS_CRED_FILE} ]] && { logging INFO "New AWS crednetial file."; return 1; }
  [[ ${ROLE} != $(sed -n "/^\[${AWS_PROFILE}\]/,/^\[\|^x_principal_arn/ s/^x_principal_arn.*:assumed-role\/\([^/]\+\).*$/\1/p" ${AWS_CRED_FILE}) ]] \
    && { logging WARN "Cannot find a profile ${AWS_PROFILE} mapped to role '${ROLE}'. New token should be requested."; return 1; }

  # check token validity if a matching profile and role is found
  token_expiration_time=$(sed -n "/^\[${AWS_PROFILE}\]/,/^\[\|^x_security_token_expires/ s/^x_security_token_expires = \(.*\)/\1/p" ${AWS_CRED_FILE})
  if [[ ! -z ${token_expiration_time} ]]; then
    if token_expiration_time_epoch=$(date -d ${token_expiration_time=} +%s); then
      logging INFO "Found a token valid till ${token_expiration_time}"
      if [[ $(expr $(date '+%s') + ${REFRESH_THRESHOLD}) -gt ${token_expiration_time_epoch} ]]; then
        logging WARN "Token will not be valid for the next ${REFRESH_THRESHOLD} seconds."
        return 1
      else
        logging INFO "Token does not need to be refreshed."
        return 0
      fi
    else
      logging INFO "Can not find valid token."
      return 1
    fi
  else 
    logging INFO "AWS profile '${AWS_PROFILE}' not found in credential file."
    return 1
  fi
}

# Parse input
cd "$(dirname ${BASH_SOURCE[0]})"
if ! OPTS=`getopt -o p:r:t:d:h --long profile:,role:,threshold:,domain:,help -- "$@"`; then
  usage
  logging ERROR "failed to parse inputs"
fi

# extract options and their arguments into variables.
eval set -- "$OPTS"
while true
do
  case "$1" in
    -p|--profile)
      AWS_PROFILE=$2 ; shift 2 ;;
    -r|--role)
      ROLE=$2 ; shift 2 ;;
    -t|--threshold)
      REFRESH_THRESHOLD=$2 ; shift 2 ;;
    -d|--domain)
      DOMAIN=$2 ; shift 2 ;;
    -h|--help)
      usage ; exit 1 ;;
    --) shift ; break ;;
    *)
      usage
      logging ERROR "Unknown input."
      exit 1 ;;
  esac
done

REFRESH_THRESHOLD=${REFRESH_THRESHOLD:-1200}       # Refresh token if it is expiring in 20 mins
[[ -z ${AWS_PROFILE} ]] && { usage; logging ERROR "Please provide the AWS profile name. Exit now."; }
[[ -x $(which saml2aws) ]] || logging ERROR "Cannot find saml2aws executable. Exit now."

if ! validate_s2a_profile; then
  ROLE=${ROLE:-"ADFS-PowerUsers"}
  read -p $'\e[96mWould you like to setup the profile now? [y/n]\e[0m' RESP
  [[ ${RESP} = "y" ]] && setup_s2a_profile || logging ERROR "Abort. Please make sure a valid saml2aws profile for ${AWS_PROFILE} is in place."
else
  # check whether the role mapping has been changed
  update_role_mapping
fi

if ! validate_aws_token; then
  logging INFO "Requesting new token ..."
  # allow longer TTL for PowerUsers role of none production accounts
  [[ ( $ROLE == "ADFS-PowerUsers"  || $ROLE == "FMADFS-PowerUsers" ) && $ACC_NUM != "042627662550" && $ACC_NUM != "128363688939" ]] && MAX_SESSION_TTL=43200 || MAX_SESSION_TTL=3600
  saml2aws login -a ${AWS_PROFILE} --session-duration=${MAX_SESSION_TTL} --verbose
fi
