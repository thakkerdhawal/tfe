#!/bin/bash
PROXY_USERNAME=${1}
PROXY_PASSWORD=${2}
CICD_TEST_PASSWORD=${3}

set -e
export http_proxy="http://${PROXY_USERNAME}:${PROXY_PASSWORD}@fm-eu-lon-proxy.fm.rbsgrp.net:8080"
export https_proxy="http://${PROXY_USERNAME}:${PROXY_PASSWORD}@fm-eu-lon-proxy.fm.rbsgrp.net:8080"
export no_proxy="127.0.0.1, localhost, *.fm.rbsgrp.net"
export HOME=/var/tmp/cicd
export ANSIBLE_LOCAL_TEMP=/tmp/.ansible-${USER}/tmp
export ANSIBLE_REMOTE_TEMP=/tmp/.ansible-${USER}/tmp

## Setup ##
cd $(dirname "$(readlink -f "${0}")")/../ansible
ansible-playbook playbooks/awsProxyJump.yml
  
for REGION in eu-west-2 eu-west-1; do  

  [[ $REGION == "eu-west-2" ]] && DNS_REGION=EuWest2
  [[ $REGION == "eu-west-1" ]] && DNS_REGION=EuWest1
  ## Bastion ##  
  ansible-playbook playbooks/cwagent/cwagent_update.yml -e "awsAcc=shared-services awsEnv=cicd awsRegion=$REGION awsComp=bastion awsCompPrivIps=bastion_hosts groupName=bastion"
  
  ## R53 ##  
  ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=nwm_lab awsEnv=cicd r53Record=www r53Zone=cicd.cloud.agilemarkets.com disable${DNS_REGION}=True"
  ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=nwm_lab awsEnv=cicd r53Record=syndicate r53Zone=cicd.cloud.natwestmarkets.com disable${DNS_REGION}=True"
  ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=nwm_lab awsEnv=cicd r53Record=filetransfer  r53Zone=cicd.cloud.natwestmarkets.com disable${DNS_REGION}=True"
  ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=nwm_lab awsEnv=cicd r53Record=fxmp-uk  r53Zone=cicd.cloud.natwestmarkets.com disable${DNS_REGION}=True"
  ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=nwm_lab awsEnv=cicd r53Record=fxmp-us  r53Zone=cicd.cloud.natwestmarkets.com disable${DNS_REGION}=True"

  ## APIGW ##
  ansible-playbook playbooks/apigw/apigw_buildProvisioner.yml -e "awsEnv=cicd awsRegion=$REGION apigwPassword=${CICD_TEST_PASSWORD}"  
  ansible-playbook playbooks/apigw/apigw_importClusterWideProperties.yml -e "awsEnv=cicd awsRegion=$REGION apigwPassword=${CICD_TEST_PASSWORD}"
  ansible-playbook playbooks/apigw/apigw_importTrustedCertificates.yml -e "awsEnv=cicd awsRegion=$REGION apigwPassword=${CICD_TEST_PASSWORD}"
  ansible-playbook playbooks/apigw/apigw_setupFxmpPort.yml -e "awsEnv=cicd awsRegion=$REGION apigwPassword=${CICD_TEST_PASSWORD}"
  
  ## Stream ##
  ansible-playbook playbooks/stream/stream_setup.yml -e "awsEnv=cicd awsRegion=$REGION streamStatusPassword=${CICD_TEST_PASSWORD}"
  
  ## Apache ##
  ansible-playbook playbooks/apache/apache_setup.yml -e "awsEnv=cicd awsRegion=$REGION apacheInstanceName=agilemarkets" 
  ansible-playbook playbooks/apache/apache_setup.yml -e "awsEnv=cicd awsRegion=$REGION apacheInstanceName=bondsyndicate"
  
  ## Cleo ##
  ansible-playbook playbooks/cleo/vlproxy_installConfig.yml -e "consulTokenPassword=${CONSUL_HTTP_TOKEN} awsEnv=cicd awsRegion=$REGION vlproxyConfigPassword=${CICD_TEST_PASSWORD}"
  
  ## R53 ##
  ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=nwm_lab awsEnv=cicd r53Record=www r53Zone=cicd.cloud.agilemarkets.com enable${DNS_REGION}=True"
  ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=nwm_lab awsEnv=cicd r53Record=syndicate r53Zone=cicd.cloud.natwestmarkets.com enable${DNS_REGION}=True"
  ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=nwm_lab awsEnv=cicd r53Record=filetransfer  r53Zone=cicd.cloud.natwestmarkets.com enable${DNS_REGION}=True"
  ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=nwm_lab awsEnv=cicd r53Record=fxmp-uk  r53Zone=cicd.cloud.natwestmarkets.com enable${DNS_REGION}=True"
  ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=nwm_lab awsEnv=cicd r53Record=fxmp-us  r53Zone=cicd.cloud.natwestmarkets.com enable${DNS_REGION}=True"
done

## Health Check ##
ansible-playbook playbooks/generic/serviceHealthCheck.yml -e "awsEnv=cicd"
