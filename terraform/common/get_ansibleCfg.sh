set -e 

delete=0
filepath="../../../ansible/ansible.cfg"
currentpath=`pwd`

#remove ansible.cfg if it is older than 7 days
find  $filepath -mtime +7 -exec rm {} \; >/dev/null 2>&1 || true

#check onsul token is not empty 
[[ ! -z ${CONSUL_HTTP_TOKEN} ]] || (echo "{\"exitstatus\": \"1\"}" && exit 1)

#should not run from networks, setup and bastion dir
( [[ $currentpath == *"networks"* ]] || [[ $currentpath == *"setup-"* ]] || [[ $currentpath == *"bastion"* ]] ) &&  echo "{\"exitstatus\": \"0\"}" && exit 0

export ANSIBLE_REMOTE_TMP=$HOME
# if ansible.cfg does not exists then run playbook
[[ ! -r  $filepath ]] && ansible-playbook ../../../ansible/playbooks/awsProxyJump.yml >/dev/null 2>&1
unset ANSIBLE_REMOTE_TMP

echo "{\"exitstatus\": \"0\"}"

exit 0
