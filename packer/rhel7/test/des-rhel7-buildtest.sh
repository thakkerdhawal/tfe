#!/bin/bash

function error_log () {
  echo "ERROR: $1"
  exit 1
}

function clean_up () {
  rm -rf ${TMP}
}

# Simulate a host key signing, which should be done at the host end at launch time 
# Usage: host_key_signing host ssh_key
function host_key_signing () {
  HOST_PUBKEY="$(ssh ${SSH_OPTIONS} ${2} ec2-user@${1} sudo cat /etc/ssh/ssh_host_ecdsa_key.pub | tr -d '\015')"
  # echo $HOST_PUBKEY
  SIGNED_PUBKEY=$(curl -sk ${VAULT_ADDR}/v1/ssh-host-signer/sign/hostrole --noproxy "*" --header "X-Vault-Token: $(cat ~/.vault-token)" -X POST -d @- << EOF | python -c 'import sys,json; print json.load(sys.stdin)["data"]["signed_key"]'
{
  "cert_type": "host",
  "public_key": "${HOST_PUBKEY}" 
}
EOF
)
  ssh ${SSH_OPTIONS} ${2} ec2-user@${1} sudo sh -c \"echo ${SIGNED_PUBKEY} \> /etc/ssh/ssh_host_ecdsa_key-cert.pub\"
}

# TODO: create vault sign-in
function vault_signin () {
  echo "get vault token"

}
TMP=/tmp/des-rhel7-buildtest
[[ ! -d ${TMP} ]] && mkdir ${TMP}
SSH_CONF=${TMP}/ssh_config
KNOWN_HOSTS=${TMP}/known_hosts
SSH_OPTIONS="-F ${SSH_CONF} -qti"
BUILD_KEY=${TMP}/des-rhel7-buildtest-key
USER_KEY=${TMP}/des-rhel7-testuser-key
export VAULT_ADDR=https://vault-dev.fm.rbsgrp.net:8200
export VAULT_SKIP_VERIFY=1

cd "$( dirname "${BASH_SOURCE[0]}" )"

# create a temp build key
[[ -r ${BUILD_KEY} ]] || ssh-keygen -t rsa -b 2048 -C "des-rhel7-buildtest" -f ${BUILD_KEY} -N '' > /dev/null || error_log "failed to create build key"

# create a temp user key
[[ -r ${USER_KEY} ]] || ssh-keygen -t rsa -b 2048 -C "des-rhel7-testuser" -f ${USER_KEY} -N '' > /dev/null || error_log "failed to create test user key"

# run terraform
terraform init || error_log "failed to initiate terraform"
terraform plan -var "aws_profile_ss=des_ss_sandbox" -var "ssh_key=${BUILD_KEY}.pub" -out ${TMP}/des-rhel7-buildtest.tfplan || error_log "failed to plan"
terraform apply ${TMP}/des-rhel7-buildtest.tfplan || error_log "failed to apply terraform plan"

BASTION_HOST=$(terraform state show aws_instance.test-bastion | grep private_ip  | awk '{print $3}')
APP_HOST=$(terraform state show aws_instance.test-app | grep private_ip  | awk '{print $3}')

# Create the ssh config for this test
cat << EOF > ${SSH_CONF}
# Bastion
Host ${BASTION_HOST}
  HostName 		${BASTION_HOST}
  User 			ec2-user
  StrictHostKeyChecking no
  ProxyCommand		none
  UserKnownHostsFile	/dev/null
  IdentityFile		${BUILD_KEY}
# App Host
Host ${APP_HOST}
  HostName 		${APP_HOST}
  User 			ec2-user
  StrictHostKeyChecking no
  UserKnownHostsFile	/dev/null
  ProxyCommand		ssh -qt -F ${SSH_CONF} ec2-user@${BASTION_HOST} -W %h:%p
EOF

# Wait for the hosts to be ready
counter=0
echo "$(date) waiting for hosts to become ready ..."
while ! ssh -o ConnectTimeout=2 ${SSH_OPTIONS} ${BUILD_KEY} ${APP_HOST} exit
do
  [[ $counter -gt 6 ]] && error_log "failed to connect to target host"
  sleep 10
  let counter=counter+1
  echo "$(date) waiting for hosts to become ready ..."
done
echo "SSH connectivity test with build key ... OK"

# Sign the user key
vault write -field=signed_key ssh-client-signer/sign/test-role public_key=@${USER_KEY}.pub > ${USER_KEY}-cert.pub || error_log "failed to sign test user key"
# Test SSH using signed user key 
sed -i "s#IdentityFile.*#IdentityFile ${USER_KEY}#g" ${SSH_CONF}
ssh ${SSH_OPTIONS} ${USER_KEY} ${APP_HOST} exit && echo "SSH test with Signed user key ... OK" || error_log "failed to connect with signed key"

# Simulate host key signing
host_key_signing ${BASTION_HOST} ${USER_KEY} && echo "Signing the host key of Bastion host ... OK" || error_log "failed to signed bastion host key"
host_key_signing ${APP_HOST} ${USER_KEY} && echo "Signing the host key of App host ... OK" || error_log "failed to signed app host key"

# create known_hosts file
# curl -sk --noproxy "*" -H "X-Vault-Token: $(cat ~/.vault-token)" ${VAULT_ADDR}/v1/ssh-host-signer/config/ca | python -c 'import sys,json; print json.load(sys.stdin)["data"]["public_key"]'
echo "@cert-authority ${BASTION_HOST}" $(curl -sk --noproxy '*' -H "X-Vault-Token: $(cat ~/.vault-token)" ${VAULT_ADDR}/v1/ssh-host-signer/config/ca | python -c 'import sys,json; print json.load(sys.stdin)["data"]["public_key"]') > ${KNOWN_HOSTS}
echo "@cert-authority ${APP_HOST}" $(curl -sk --noproxy '*' -H "X-Vault-Token: $(cat ~/.vault-token)" ${VAULT_ADDR}/v1/ssh-host-signer/config/ca | python -c 'import sys,json; print json.load(sys.stdin)["data"]["public_key"]') >> ${KNOWN_HOSTS}

# enable strict host key check
sed -i "s/StrictHostKeyChecking.*/StrictHostKeyChecking yes/g" ${SSH_CONF}
sed -i "s#UserKnownHostsFile.*#UserKnownHostsFile ${KNOWN_HOSTS}#g" ${SSH_CONF}
ssh ${SSH_OPTIONS} ${USER_KEY} ${APP_HOST} exit && echo "SSH test with Signed host key ... OK" || error_log "failed to connect to a host with signed key"


# clean_up
terraform destroy -var "aws_profile_ss=des_ss_sandbox" -var "ssh_key=${BUILD_KEY}.pub" || error_log "failed to destroy terraform build"
clean_up

