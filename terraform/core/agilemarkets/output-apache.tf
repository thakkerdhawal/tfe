
output "apache_ansible_playbooks" {
  description = "Playbooks to run after apache infrastructure provisioning"
  value       = <<EOF

## Ansible playbook commands for apache post install
ansible-playbook playbooks/apache/apache_setup.yml -e "awsEnv=${local.environment}" -e "awsRegion=${local.region}" -e "apacheInstanceName=agilemarkets"
ansible-playbook playbooks/apache/apache_setup.yml -e "awsEnv=${local.environment}" -e "awsRegion=${local.region}" -e "apacheInstanceName=bondsyndicate"
**** END - Apache  post build ****
EOF
}

