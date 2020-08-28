# Overview

This is Terraform code for importing a certificate to AWS Certificate Manager (ACM)

# Pre Reqs

The .pfx file must have been converted in to seperate pem files for the cert, key and CA cert chain.

# Variables

You must pass through the cert, key and CA cert chain files to Terraform. This can either be via a file reference or have the contents of the PEM file as a variable. If passing as a variable it'll probably be easier to do this by creating a terraform.tfvars file with the variables in.

* cert       - Variable with the base64 encoded certificate
* key        - Variable with the base64 encoded key (unencrypted)
* cert_chain - Variable with the base64 encoded CA Certificate Chain

* cert_file       - Location of the certificate file
* key_file        - Location of the key file (unencrypted)
* cert_chain_file - Location of the CA Certificate chain file

# Dependency on other Terraform workspaces

N/A

# Note

After successful import the ARN is output. The following steps should then be followed.
1. The appropriate variable in the consul json file should be updated in https://stash.dts.fm.rbsgrp.net/projects/DEP/repos/nwm_infra_tf_engineering/browse/consul/ using the standard procdeure.
2. The consul json file should be imported to consul
3. The Terraform workspace for the resource that is updated should be run with an apply

**Important** The local import-certificate/terraform.tfstate.d directory should be removed before each import to ensure previous certificates aren't deleted by accident.

