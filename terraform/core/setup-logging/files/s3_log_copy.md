# Overview

This Python Lambda Script when triggered by a S3 bucket event copies the object from the source S3 bucket to a destination bucket passed through to the script by an environment variable.

## Trigger Event
The script designed to be triggered by a S3 bucket event of s3:ObjectCreated:*. 

## IAM Role Policy requirements
The Lambda function needs to run with a Role that has the following permissions.
``` {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:PutObjectAcl",
                "s3:PutObject",
                "s3:GetObject",
                "logs:PutLogEvents",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        }
    ]
}
```

## Environement Variables
The Lambda function accepts the following Environment Variable
* **target_bucket** - Mandatory - The Target bucket to copy the log file to
* **target_prefix** - Optional - The prefix to add to the key on the destination

## Target Bucket policy
The Target bucket must contain the following policy.
```{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "lambda-s3-log-copy",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::724329805838:role/lambda-s3-log-copy"
            },
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::bucketname",
                "arn:aws:s3:::bucketname/*"
            ]
        }
    ]
}
```

