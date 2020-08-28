# apigw_importClusterWideProperties.yml

Ansible playbook to import list of Cluster Wide Properties 

## Overview

Create or update a list of Cluster Wide Properties defined as key value pairs in YAML file on target Gateway. 

The main use cases are:

1. create new Cluster Wide Properties
2. update existing Cluster Wide Properties (no action if the value of existing CWP has not changed)

*Note*: The playbook will not delete any Cluster Wide Property.
 
## Prerequisites

1. Consul access token is required to read KV. It can either be defined in environment var **CONSUL_HTTP_TOKEN** or pass into the playbook as extra var **consulTokenPassword**
2. A gateway user with write permission. 'ssgconfig' user by default.
3. A list of Cluster Wide Properties (default: defined in files/config/[nonprod|prod].yml)

## Variables Used

The following vars must be passed into the playook as extra vars:
- awsEnv: target environment
- awsRegion: target AWS region

The following vars are optional depends on the use cases:
- gatewayConfigFile: YAML file of Gateway Configuration to import

The following vars are required by the roles and have been defined as groups_var for apigw host group. They can be passed into the playbook as extra vars to overwrite default values:
- apigwMgmtEndpoint: default to "https://localhost:8443"
- apigwUser: default to "ssgconfig"
- apigwPassword: default to the initial password stored in Consul. 

## Getting Started

Example 1: import the default Cluster Wide Properties list
```
$ export CONSUL_HTTP_TOKEN=XXXX
ansible-playbook playbooks/apigw/apigw_importClusterWideProperties.yml -e "awsEnv=lab" -e "awsRegion=eu-west-1" [-e "apigwPassword=XXXX"]
```

Example 2: import Cluster Wide Properties in a given file
```
$ export CONSUL_HTTP_TOKEN=XXXX
ansible-playbook playbooks/apigw/apigw_importClusterWideProperties.yml -e "awsEnv=lab" -e "awsRegion=eu-west-1" -e "clusterPropertiesFile=files/config/prod.yml" [-e "apigwPassword=XXXX"]
```
