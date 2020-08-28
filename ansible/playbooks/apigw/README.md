# List of Playbooks
## apigw_buildProvisioner.yml
This playbook performs the basic configuration of the API Gateway and needs to be executed first after the EC2 instance provisioning. 

## apigw_importClusterWideProperties.yml
This playbook can be used to update Cluster Wide Properties on the Gateway.

## apigw_migrateService.yml
This playbook is used to create or update services on the Gateway.

## apigw_importTrustedCertificates.yml
This playbook can be used to import or update trusted certificates on the Gateway.

## apigw_setupFxmpPort.yml
This playbook is used to setup dedicted listener ports for FXMP.

## apigw_updatePassword.yml
This playbook is used to update password of Gateway user.

# Examples
For a fresh installation, below is the typical execution sequence. 

```
ENV="lab"
REGION="eu-west-2"

ansible-playbook playbooks/apigw/apigw_buildProvisioner.yml -e "awsEnv=${ENV} awsRegion=${REGION}"
ansible-playbook playbooks/apigw/apigw_migrateService.yml -e "awsEnv=${ENV} awsRegion=${REGION} targetService=all"
ansible-playbook playbooks/apigw/apigw_importClusterWideProperties.yml -e "awsEnv=${ENV} awsRegion=${REGION}"
ansible-playbook playbooks/apigw/apigw_importTrustedCertificates.yml -e "awsEnv=${ENV} awsRegion=${REGION}"
ansible-playbook playbooks/apigw/apigw_setupFxmpPort.yml -e "awsEnv=${ENV} awsRegion=${REGION}" 
ansible-playbook playbooks/apigw/apigw_updatePassword.yml -e "awsEnv=${ENV} awsRegion=${REGION}" -e 'newApigwPassword=XXXX'
```
