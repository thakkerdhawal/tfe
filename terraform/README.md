# Terraform build plan for NatWestMarkets Secure Network Perimeter in AWS
These Terraform templates create the infrastructure required for the new NWM SNP environment in AWS. 

# Common Pre-requisite
While we aim to fully automate the build, some resources need to be setup manually or through other process in advance, until we have toolings available to address them.

* Access to a Jump server
Because of rules on CNF firewall, we have a number of designated jump hosts that are allowed to connect into AWS network via CNF. Therefore, access to those jump hosts are required.

https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/AE+-+Products+-+AWS+-+NatWestMarkets

* Access to proxy server
AWS API are public endpoints. So the requests need to be routed through a Web Proxy. You need to setup proxy access for your session. For example:
```
export https_proxy='http://USERNAME:PASSWORD@fm-eu-lon-proxy.fm.rbsgrp.net:8080'
export http_proxy='http://USERNAME:PASSWORD@fm-eu-lon-proxy.fm.rbsgrp.net:8080'
export no_proxy="127.0.0.1, localhost, *.fm.rbsgrp.net"
```

* Able to access target AWS account via ADFS (europa account required)
To see how to request ADFS access, please see: https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/AWS+SOP%3A+Access+Model+-+DEng+Support+using+ADFS

* AWS credential and config file
You need to make sure you have a valid access token for the AWS profiles you use. You could either setup it up manually or use this script: [auth_adfs.sh](../scripts)
You 
Below is an example, you are free to give the profiles different names:
```
# europa user
./auth_adfs.sh -p nwm_test
# fm user
./auth_adfs.sh -p nwm_test -r FMADFS-PowerUsers -d fm
```

* Access to Terraform binary
Terraform is available on the jump box. **It is not recommended to run your own version, as it may produce imcompatible states**. To verify your access:
```
> which terraform
/usr/local/bin/terraform

> terraform version
Terraform v0.11.5
```

* Access to required Consul token
Since we use Consul as a backend and configuration store, you need to have the Consul token with required ACL. Once you have it, it should be made available through environment variable:
```
export CONSUL_HTTP_TOKEN="XXXXXXXXXXXXXXXXX" 
```
To see which TOKEN you should be using: https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/AE+-+Products+-+AWS+-+NatWestMarkets+-+Terraform+-+Consul+Layout+and+Design

* Define variables in Consul
Before running the build plan, you need to make sure all the variables have been setup in Consul, this must be done using process defined [here](consul/).

* Make sure all the Prerequisites documented here have been completed:
https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/AE+-+Products+-+AWS+-+NatWestMarkets+-+Terraform+-+Prerequisites

* The default SSH key we use is expected to be under the root directory of this repo, or specify the location with `-var "ssh_private_key=/PATH/MY_SSH_KEY"`


# How to run

Terraform needs to be executed against a specific workspace under a given directory. The directory structure for our Terraform templates are `<AWS_ACCOUNT>/<COMPONENT>`, and workspaces need to follow the naming convention `<ENV>_<AWS_ACCOUNT>_<COMPONENT>_<REGION>`. 

We use a [wrapper script](../scripts/tf_wrapper.sh) to help managing different workspaces and components:

```text
  Usage: ./tf_wrapper.sh -d <directory> -p <profile> -r <region> -a <action> [-c <cred_file>] [-o <true|false>] [-V] [-h]
    -p|--profile: (Required) AWS Profile
    -r|--region: (Required) AWS region [eu-west-1|eu-west-2]
    -e|--env|--environment: (Required) target environment, i.e [lab|cicd|nonprod|prod]
    -a|--action: (Required) Supported actions are:
         plan: plan only.
         apply: plan and apply
         destroy: destroy straightaway
         apply_and_destroy: plan, apply and then destroy
    -d|--dir|--directory: (Optional, default to current directory) directory of terraform templates.
    -v|--vars: (Optional, default to empty) Extra vars for Terraform.
    -c|--cred_file (Optional, default to ~/.aws/credentials): AWS credential file
    -o|--autoapprove: (Optional, default to false) Process without prompt before apply or destroy. [true|false]
    -h|--help: display this message
    -V|--verbose: display DEBUG messages

  Example:
         ./tf_wrapper.sh  --env lab --profile nwmss_test --region eu-west-2 --action plan
         ./tf_wrapper.sh  -e lab -p nwm_test -r eu-west-2 -a apply -v aws_profile_ss=nwmss_test -o true -V
         ./tf_wrapper.sh  -d TARGET_DIR -e nonprod -p nwm_nonprod -r eu-west-2 -a destroy -c PATH_TO_CRED
```

You can also run Terraform binary directly:
```bash
# Example
ENV=lab; AWS_ACCOUNT=shared-services; PROFILE=nwmss_test; REGION=eu-west-2;
cd ${AWS_ACCOUNT}/${COMPONENT}
terraform init -backend-config="path=application/nwm/${ENV}/terraform/${AWS_ACCOUNT}/state/tfstate" -plugin-dir=/usr/local/bin/.terraform/plugins/linux_amd64
terraform workspace select ${ENV}_${AWS_ACCOUNT}_${COMPONENT}_${REGION}
terraform plan -var "aws_profile=${PROFILE}" -out /tmp/tf-build.$(terraform workspace show).$(whoami).tfplan
terraform apply  /tmp/tf-build.$(terraform workspace show).$(whoami).tfplan
terraform destroy -var "aws_profile=${PROFILE}" /tmp/tf-build.$(terraform workspace show).$(whoami).tfplan
```
