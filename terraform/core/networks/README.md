# Overview

This is Terraform templates for building NWM Core VPC and subnets.  

# Dependency on other Terraform workspaces

* shared-services/networks
* shared-services/bastion

# Notes

This templates requires a shared-service AWS account profile to be provided as input variable. For example:

```bash
tf_wapper.sh  -e lab -p nwm_test -r eu-west-2 -a apply 
```
