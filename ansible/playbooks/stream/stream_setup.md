# stream_setup.yml

Ansible playbook to deploy Caplin Liberator instance on AWS EC2 instances

## Overview

EC2 instances are provisioned in NWM Core VPC, and this playbook will perform the following actions:

- extract the target instances IP from Consul and add to inventory
- download Caplin Liberator and Java binary packages from Artifactory and upload and unarchive to target hosts (role: generic_afServerFileCopy)
- configures Caplin Liberator instance on target hosts (role: stream_config)


## Prerequisites

Consul access token is required to read KV. It can either be defined in environment var **CONSUL_HTTP_TOKEN** or pass into the playbook as extra var **consulTokenPassword**

## Variables Used

The following vars must be passed into the playook as extra vars:
- awsEnv
- awsRegion
- streamStatusPassword

The following vars are required by the roles and have been defined in vars_files/stream. They can also be passed into the playbook as extra vars to overwrite default values:

- theUser: ec2-user
- afBase: https://artifactory-1.dts.fm.rbsgrp.net/artifactory/eComm-public-releases-local
- javaDest: /ecomm/java/
- streamDest: /ecomm/caplin/liberator/stream-agilemarkets/current/
- streamUser: ec2-user

## Optional Variables
- targetHosts: Set this variable when you want to run stream_config role on specific targeted hosts rather than all the hosts in a group. This is used in terraform to run stream_config role on targeted host (as we may not rebuild all the hosts in a given awsRegion).
Example:
$ ansible-playbook playbooks/stream/stream_setup.yml -e "awsEnv=lab" -e "awsRegion=eu-west-2" -e "targetHosts=['10.10.1.1']"


## Getting Started


Example:
```
$ export CONSUL_HTTP_TOKEN=XXXX
$  ansible-playbook playbooks/stream/stream_setup.yml -e "awsEnv=lab" -e "awsRegion=eu-west-2" -e "streamStatusPassword=xxx"

