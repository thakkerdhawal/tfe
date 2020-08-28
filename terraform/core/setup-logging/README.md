# Overview

This is Terraform templates for setting up Logging in NWM Core

# Dependency on other Terraform workspaces

* core/setup-iam
* shared-services/setup-logging

# Note

1. Creates a S3 bucket to be used for other S3 Buckets access logs
2. Creates a Lambda function that is triggered by any update in the S3 bucket containing the S3 Access logs and then copies those logs to the SharedServices central Logging bucket

