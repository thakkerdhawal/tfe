# Overview
This is Terraform templates for providing logging solution for AWS services
- Logging buckets are created for s3access,awsconfig,cloudfront,cloudtrail,cloudwatch,elblog,vpcflow,waf
- Buckets are configured in both London and Ireland regions
- To create replica buckets,specify a provider for the replica region
- Separate bucket policies are defined for each service
- Logging buckets should have the below features enabled
  - versioning,lifecycle rule configured,ACL,replication configuration,server side encryption algorithm,prevent destroy
- Refer the below confluence page for detailed understanding
  - https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/AE+-+Products+-+AWS+-+NatWestMarkets+-+Logging

# Dependency on other Terraform workspaces
.shared-services/setup-iam


