# Overview

This is Terraform templates for setting up IAM roles, users, policies and ADFS access of an AWS account

# Dependency on other Terraform workspaces

N/A

# Note

1. This should be executed using an account with IAM admin permission
2. Since IAM resources are account wide, this is not region specific and should only have one workspace per **AWS account**. While technically this can be executed against any region, we have chosen eu-west-2 to be the region that holds the state file, and it is hardcoded in the templates.  This should **NOT** be executed in CICD environment as it shares the same AWS account with LAB.
