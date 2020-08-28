# apigw_setupFxmpPort.yml

Ansible playbook to setup dedicated listener port for FXMP service

## Overview

FXMP services on the CA API Gateway is different from our standard REST services:
- it has a bespoke policy
- it requires client certificate authentication, therefore we need to expose a port exposed to clients. In order to present specific FXMP service certificate, it listens on specific port
- each port is mapped to a single FXMP service
- there are multiple FXMP services of different domains and backends hosted on one Gateway, therefore requires multiple ports

This playbook is to create or update a HTTPS listener port, which is:
- mapped to a given (FXMP) service
- associated to a specific certificate (i.e private key in Gateway's term). The certificate can be imported or updated as part of the play.
- if target certificate is found on Gateway and no private key is provided to the playbook, the playbook will create a dummy certificate for testing
- above mappings are defined in the gateway configuration file

The main use cases are:

1. import new certificate and create new listener port
2. update (e.g renew) certificate and update the associated listener port
3. create new listener port with existing certificate
4. update the name or number of an existing port, or the service it maps to, or the certificate it associated with.

The playbook will not process in the following scenarios:
- the service this port is mapped to has not been created on the Gateway
- associated certificate is found on Gateway and private key is providated to the playbook, but 'forceUpdate=true' is not specified
- the given port name and number are used by two different existing ports

When 'forceUpdate=true' is specified, the playbook will update the existing certificate or port without checking the following:
- whether the certificate is used by other ports
- whether the port was associated to a different certificate
 
## Prerequisites

1. Consul access token is required to read KV. It can either be defined in environment var **CONSUL_HTTP_TOKEN** or pass into the playbook as extra var **consulTokenPassword**
2. A gateway user with write permission. 'ssgconfig' user by default.
3. The target port number to be updated
4. A pkcs12 format certificate (provided in base64 format, see example below) and its passphrase

## Variables Used

The following vars must be passed into the playook as extra vars:
- awsEnv: target environment
- awsRegion: target AWS region
- targetPortNumber: target listener port number

The following vars are optional depends on the use cases:
- keyEncoded: base64 encoded form of a pkcs12 certificate file 
- keyPassword: passphrase of the certificate 
- forceUpdate: to confirm overwriting of existing objects

The following vars are required by the roles and have been defined as groups_var for apigw host group. They can be passed into the playbook as extra vars to overwrite default values:
- apigwMgmtEndpoint: default to "https://localhost:8443"
- apigwUser: default to "ssgconfig"
- apigwPassword: default to the initial password stored in Consul.

## Getting Started

Example use case 1: import new certificate and create new listener port
```
$ export CONSUL_HTTP_TOKEN=XXXX
$ ansible-playbook playbooks/apigw/apigw_setupFxmpPort.yml -e 'awsEnv=lab' -e 'awsRegion=eu-west-1' -e 'targetPortNumber=9601' \
-e "keyEncoded=$(base64 /tmp/uat3.fxmicropay.com-exp2019.pfx | tr -d '\r\n')" -e 'keyPassword=XXXXXXXX' [-e "apigwPassword=XXXX"]
```
Example use case 2: update (e.g renew) certificate and update the associated listener port
```
$ export CONSUL_HTTP_TOKEN=XXXX
$ ansible-playbook playbooks/apigw/apigw_setupFxmpPort.yml -e 'awsEnv=lab' -e 'awsRegion=eu-west-1' -e 'targetPortNumber=9601' \
-e "keyEncoded=$(base64 /tmp/uat3.fxmicropay.com-exp2019.pfx | tr -d '\r\n')" -e 'keyPassword=XXXXXXXX' \
-e 'forceUpdate=true' [-e "apigwPassword=XXXX"]
```
Example use case 3: create new listener port with existing certificate
```
$ export CONSUL_HTTP_TOKEN=XXXX
$ ansible-playbook playbooks/apigw/apigw_setupFxmpPort.yml -e 'awsEnv=lab' -e 'awsRegion=eu-west-1' -e 'targetPortNumber=9601' \
[-e "apigwPassword=XXXX"]
```
Example use case 4: update the name or number of an existing port, or the service it maps to, or the certificate it associated with.
```
$ export CONSUL_HTTP_TOKEN=XXXX
$ ansible-playbook playbooks/apigw/apigw_setupFxmpPort.yml -e 'awsEnv=lab' -e 'awsRegion=eu-west-1' -e 'targetPortNumber=9601' \
-e 'forceUpdate=true' [-e "apigwPassword=XXXX"]
```

