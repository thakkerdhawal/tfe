# logging_setup.yml

Ansible playbook to install and configure Splunk on AWS logging EC2 instances

## Overview

EC2 instances are provisioned in NWM Shared-Services VPC, and this playbook will perform the following actions:

- extract the target instances IP from Consul and add to inventory
- download Splunk package from Artifactory and upload to target hosts (role: generic_afServerFileCopy)
- install and configure Splunk on target hosts (role: splunk_install)
- only configure tasks will be executed if target Splunk installation already exists
- by default, Splunk will use a dummy CA and self-signed certificates. This can be overwritten by providing "splunkCertPassword" and "splunkCert"

## Prerequisites

Consul access token is required to read KV. It can either be defined in environment var **CONSUL_HTTP_TOKEN** or pass into the playbook as extra var **consulTokenPassword**

## Variables Used

The following vars must be passed into the playook as extra vars:
- awsEnv
- awsRegion
- splunkRole (splunk_web or splunk_fwd)
- adminPassword (if it is fresh installation)
- splunkCert (if customised cert is to be used, must be provided with splunkCertPassword)
- splunkCertPassword (if customised cert is to be used, must be provided with splunkCert)

The following vars are required by the roles and have been defined in vars_files/logging for the logging server group. They can also be passed into the playbook as extra vars to overwrite default values:

- theUser
- afUrl
- afFile
- enableWebGui

## Getting Started

Example 1: install Splunk Web instance with default (self-signed) certificate 
```
$ export CONSUL_HTTP_TOKEN=XXXX
$ ansible-playbook playbooks/logging/logging_setup.yml -e "awsEnv=lab" -e "awsRegion=eu-west-2" -e 'adminPassword=XXXX' -e 'splunkRole=splunk_web'
```

Example 2: install Splunk Forwarder instance with customised (RBS issued) certificate 
```
$ export CONSUL_HTTP_TOKEN=XXXX
$ ansible-playbook playbooks/logging/logging_setup.yml -e "awsEnv=lab" -e "awsRegion=eu-west-2" -e 'adminPassword=XXXX' -e 'splunkRole=splunk_fwd' -e 'splunkCertPassword=XXXX' -e "splunkCert='$(cat ecommsplunkforwarder.fm.rbsgrp.net.pem)'"
```
