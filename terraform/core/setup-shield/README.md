# Overview

This is Terraform templates for setting up a Lambda function that checks daily that all resources are protected by AWS Shield Advanced.

It also enables AWS Shield Advanced if it's not already enabled. Note that this has a cost of $3000USD a month consolidated under a payer account, so you only pay once per organisation. Ensure this is only installed where this is approved.

# Dependency on other Terraform workspaces

* setup-iam

# Note

Lambda function will do the following. It's set to run every day at 1am
1. Enables shield if not already enabled
2. Enables DDoS Response Team (DRT) Role access
3. If applicable (Shared services only) grants DRT access to S3 buckets. (Env variable shield_drt_buckets)
4. Configures the notification email address list (Env variable shield_notification_email)
5. Finds all resources across regions. 
6. A cloudwatch alarm is setup to monitor the DDoSDetected metric. 
7. As cloudwatch is regional this component needs to be run in both regions. In eu-west-2 the lambda function will also be installed and a Cloudwatch metric will be setup in us-east-1 at the same time (used for CloudFront, Route53).

As the Lambda function only needs to run once we've selected eu-west-2 (LON) to be setup in.
