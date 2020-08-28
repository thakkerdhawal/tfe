# apigw_importTrustedCertificates.yml

Ansible playbook to import list of Trusted Certificates 

## Overview

Create or update a list of Trusted Certificates defined as key value pairs in YAML file on target Gateway. 

The main use cases are:

1. create new Trusted Certificates
2. update existing Trusted Certificates (only when forceUpdate is true)

*Note*: 
1) The playbook will not delete any Trusted Certificate. 
2) The name of the Truested Certificate in Gateway must match the name of the PEM file, i.e \<trustedCertificateName\>.pem
 
## Prerequisites

1. Consul access token is required to read KV. It can either be defined in environment var **CONSUL_HTTP_TOKEN** or pass into the playbook as extra var **consulTokenPassword**
2. A gateway user with write permission. 'ssgconfig' user by default.
3. A list of Trusted Certificates defined in a dictionary object (default: in files/config/[nonprod|prod].yml). Each certificate in the list needs to have name and enabled properties. For example:
```
trustedCertificates:
  - name: DigiCert Global CA G2
    properties: "trustAnchor, trustedForSigningServerCerts, revocationCheckingEnabled"
  - name: Royal Bank of Scotland Commercial Issuing CA1
    properties: "trustedForSigningServerCerts, revocationCheckingEnabled"
  - name: Royal Bank of Scotland Commercial Root CA
    properties: "trustAnchor, revocationCheckingEnabled"
```
4. Certificates in the list needs to be in PEM format and stored under 'files/trustedCertificates'

## Variables Used

The following vars must be passed into the playook as extra vars:
- awsEnv: target environment
- awsRegion: target AWS region

The following vars are optional depends on the use cases:
- forceUpdate: false by default. Set to true if you want to update an existing certificate or its properties
- gatewayConfigFile: YAML file of Gateway Configuration to import

The following vars are required by the roles and have been defined as groups_var for apigw host group. They can be passed into the playbook as extra vars to overwrite default values:
- apigwMgmtEndpoint: default to "https://localhost:8443"
- apigwUser: default to "ssgconfig"
- apigwPassword: default to the initial password stored in Consul.

## Getting Started

Example 1: create new Trusted Certificates, ignore existing certificate
```
$ export CONSUL_HTTP_TOKEN=XXXX
ansible-playbook playbooks/apigw/apigw_importTrustedCertificates.yml -e "awsEnv=nonprod" -e "awsRegion=eu-west-2" [-e "apigwPassword=XXXX"]
```

Example 2: create new and update existing Trusted Certificates 
```
$ export CONSUL_HTTP_TOKEN=XXXX
ansible-playbook playbooks/apigw/apigw_importTrustedCertificates.yml -e "awsEnv=nonprod" -e "awsRegion=eu-west-2" -e "forceUpdate=true" [-e "apigwPassword=XXXX"]
```
