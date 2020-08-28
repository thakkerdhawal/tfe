# manageSystemd.yml 

Ansible playbook to manage (start or stop) systemd services 

## Overview



## Prerequisites

Consul access token is required to read KV when targetHosts is not set. It can either be defined in environment var **CONSUL_HTTP_TOKEN** or pass into the playbook as extra var **consulTokenPassword**

## Variables Used

The following vars must be passed into the playook as extra vars:
- awsEnv
- state: allowedState [ reloaded, restarted, started, stopped]
- serviceName 

The playbook can either get hosts ips from consul if consulKey is set or user needs to pass list of targetHosts to playbook. 
- consulKey 
- targetHosts

## Getting Started
ansible-playbook playbooks/generic/manageSystemd.yml -e awsEnv=lab -vv -e state=stopped -e serviceName=httpd  -e consulKey="https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/terraform/core/outputs/agilemarkets/eu-west-2/apache_instances_private_ips"

OR

ansible-playbook playbooks/generic/manageSystemd.yml -e awsEnv=lab -vv -e state=stopped -e serviceName=httpd -e targetHosts="['10.8.100.8']"

