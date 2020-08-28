output "apigw_ansible_playbooks" {
  description = "Playbooks to run after infrastructure provisioning"
  value       = <<EOF

**** START - API Gateway post build ****
**** After the API Gateway is built, the following Ansible Playbooks need to be executed to complete the build ****
ansible-playbook playbooks/apigw/apigw_buildProvisioner.yml -e 'awsEnv=${local.environment} awsRegion=${local.region}'
ansible-playbook playbooks/apigw/apigw_importClusterWideProperties.yml -e 'awsEnv=${local.environment} awsRegion=${local.region}'
ansible-playbook playbooks/apigw/apigw_importTrustedCertificates.yml -e 'awsEnv=${local.environment} awsRegion=${local.region}'
ansible-playbook playbooks/apigw/apigw_setupFxmpPort.yml -e 'awsEnv=${local.environment} awsRegion=${local.region} portNumber=9601 portName=fxmp-uk serviceName=FXMP_CORE_UK keyAlias=XXXX keyPassword=XXXX keyFile=XXXX.pfx'
ansible-playbook playbooks/apigw/apigw_setupFxmpPort.yml -e 'awsEnv=${local.environment} awsRegion=${local.region} portNumber=9602 portName=fxmp-us serviceName=FXMP_CORE_US keyAlias=XXXX keyPassword=XXXX keyFile=XXXX.pfx'
# PROD ONLY: ansible-playbook playbooks/apigw/apigw_setupFxmpPort.yml -e 'awsEnv=prod awsRegion=${local.region} portNumber=9603 portName=fxmp-int-uk serviceName=FXMP_CORE_INT_UK keyAlias=XXXX keyPassword=XXXX keyFile=XXXX.pfx'
# PROD ONLY: ansible-playbook playbooks/apigw/apigw_setupFxmpPort.yml -e 'awsEnv=prod awsRegion=${local.region} portNumber=9604 portName=fxmp-int-us serviceName=FXMP_CORE_INT_US keyAlias=XXXX keyPassword=XXXX keyFile=XXXX.pfx'
ansible-playbook playbooks/apigw/apigw_updatePassword.yml -e 'awsEnv=${local.environment} awsRegion=${local.region} newApigwPassword=XXXX'
**** END - API Gateway post build ****
EOF
}

