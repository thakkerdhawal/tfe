# apigw_updatePassword.yml

Ansible playbook to update API Gateway password

## Overview

Update API Gateway user password of:
- Policy Manager user ssgconfig

The main use cases are:

1. change the initial password of Gateway users after build completion
2. update/rotate existing password 

*Note*: The new password must comply with password policy
 
## Prerequisites

1. Consul access token is required to read KV. It can either be defined in environment var **CONSUL_HTTP_TOKEN** or pass into the playbook as extra var **consulTokenPassword**
2. A gateway user with write permission. 'ssgconfig' user by default.
3. New password checked out from CyberArk

## Variables Used

The following vars must be passed into the playook as extra vars:
- awsEnv: target environment
- awsRegion: target AWS region
- At lease one of the following:
  - newApigwPassword: new password for the Policy Manager user to be updated

The following vars are optional depends on the use cases:
- apigwUser: the user to be updated. Default to ssgconfig
- apigwPassword: current password of apigwUser. Default to the initial password stored in Consul. 

The following vars are required by the roles and have been defined as groups_var for apigw host group. They can be passed into the playbook as extra vars to overwrite default values:
- apigwMgmtEndpoint: default to "https://localhost:8443"

## Getting Started

Example 1: Change the initial password after build completion (`apigwPassword` can be omitted as it can be retrieved from Consul)
```
$ export CONSUL_HTTP_TOKEN=XXXX
# Update PM user password
ansible-playbook playbooks/apigw/apigw_updatePassword.yml -e 'awsEnv=lab awsRegion=eu-west-1 newApigwPassword=XXXX'
```

Example 2: update/rotate existing password 
```
$ export CONSUL_HTTP_TOKEN=XXXX
# Update only user password
ansible-playbook playbooks/apigw/playbooks/apigw/apigw_updatePassword.yml -e 'awsEnv=lab awsRegion=eu-west-1 apigwPassword=XXXX newApigwPassword=XXXX'
```

