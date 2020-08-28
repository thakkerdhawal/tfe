# EIP Attached Rule 
resource "aws_config_config_rule" "eip_attached" {
  name  = "nwm_eip_attached"

  source {
    owner             = "AWS"
    source_identifier = "EIP_ATTACHED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

# S3 Bucket loggin Enabled Rule
resource "aws_config_config_rule" "s3_logging_enabled" {
  name  = "nwm_check_s3_bucket_logging"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LOGGING_ENABLED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

# IAM Policy Admin Access Check Rule
resource "aws_config_config_rule" "iam_policy_no_statements_with_admin_access" {
    name = "nwm_iam_policy_no_statements_with_admin_access"

    source {
        owner               = "AWS"
        source_identifier   = "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS"
    }

    depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

# RDS Storage Encryption Check Rule
resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "nwm_rds_storage_encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

# ACM Certificate Expiration Check Rule
resource "aws_config_config_rule" "acm-certificate-expiration-check" {
  name = "nwm_acm_certificate_expiration_check"

  source {
    owner             = "AWS"
    source_identifier = "ACM_CERTIFICATE_EXPIRATION_CHECK"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

# RDS Instance Public Access Check Rule
resource "aws_config_config_rule" "rds_instance_public_access_check" {
  name = "nwm_rds_instance_public_access_check"

  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#RDS Snapshot Public Prohibition Check Rule
resource "aws_config_config_rule" "rds_snapshots_public_prohibited" {
  name = "nwm_rds_snapshots_public_prohibited"

  source {
    owner             = "AWS"
    source_identifier = "RDS_SNAPSHOTS_PUBLIC_PROHIBITED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

# IAM Root Access Key Check Rule
resource "aws_config_config_rule" "iam_root_access_key_check" {
  name = "nwm_iam_root_access_key_check"

  source {
    owner             = "AWS"
    source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#S3 Bucket Public Write prohibition Check Rule 
resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  name = "nwm_s3_bucket_public_write_prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#S3 Bucket Public Read Prohibition Check Rule 
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "nwm_s3_bucket_public_read_prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

# CloudTrail Enabled Check Rule
resource "aws_config_config_rule" "cloudtrail_enabled" {
  name  = "nwm_check_cloudtrail"

  input_parameters = <<PARAMETERS
  {
    "s3BucketName" : "logging-${data.aws_iam_account_alias.current.account_alias}-cloudtrail-${local.region}"
  }
PARAMETERS

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

# Encrypted Volumes Check Rule
resource "aws_config_config_rule" "encrypted_volumes" {
  name  = "nwm_encrypted_volumes"

  input_parameters = <<PARAMETERS
  {
    "kmsId" : "${data.aws_kms_alias.ebs_volume.target_key_arn}"

   }

PARAMETERS

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

# CloudTrail Multiregion Check Rule
resource "aws_config_config_rule" "multi_region_cloudtrail_enabled" {
  name  = "nwm_multi_region_cloudtrail_enabled"

  input_parameters = <<PARAMETERS
  {
    "s3BucketName" : "logging-${data.aws_iam_account_alias.current.account_alias}-cloudtrail-${local.region}"
   }

PARAMETERS

  source {
    owner             = "AWS"
    source_identifier = "MULTI_REGION_CLOUD_TRAIL_ENABLED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#S3 Bucket Server Encryption Check Rule
resource "aws_config_config_rule" "s3_bucket_server_side_encryption_enabled" {
  name = "nwm_s3_bucket_server_side_encryption_enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#Lambda Function Public Prohibition Check Rule
resource "aws_config_config_rule" "lambda_function_public_access_prohibited" {
  name = "nwm_lambda_function_public_access_prohibited"

  source {
    owner             = "AWS"
    source_identifier = "LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED Check Rule
resource "aws_config_config_rule" "cloud_trail_log_file_validation_enabled" {
  name = "nwm_cloud_trail_log_file_validation_enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

 #EC2_INSTANCE_DETAILED_MONITORING_ENABLED Check Rule
resource "aws_config_config_rule" "ec2_instance_detailed_monitoring_enabled" {
  name = "nwm_ec2_instance_detailed_monitoring_enabled"

  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_DETAILED_MONITORING_ENABLED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

 # Instances In VPC Check Rule
resource "aws_config_config_rule" "instances_in_vpc" {
  name = "nwm_instances_in_vpc"

  source {
    owner             = "AWS"
    source_identifier = "INSTANCES_IN_VPC"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

# VPC Default Security check Rule
resource "aws_config_config_rule" "vpc_default_security_group_closed" {
  name  = "nwm_vpc_default_security_group_closed"

  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#  Access Key Rotated Check Rule
resource "aws_config_config_rule" "access_keys_rotated" {
  name  = "nwm_access_keys_rotated"

  input_parameters = <<PARAMETERS
  {
    "maxAccessKeyAge" : "90"
   }

PARAMETERS

  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}


#iam-user-unused-credentials-check Rule
resource "aws_config_config_rule" "iam_user_unused_credentials_check" {
  name  = "nwm_iam_user_unused_credentials_check"

  input_parameters = <<PARAMETERS
  {
    "maxCredentialUsageAge" : "90"
   }

PARAMETERS

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_UNUSED_CREDENTIALS_CHECK"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#S3_BUCKET_SSL_REQUESTS_ONLY check Rule
resource "aws_config_config_rule" "s3_bucket_ssl_requests_only" {
  name  = "nwm_s3_bucket_ssl_requests_only"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

# ROOT_ACCOUNT_MFA_ENABLED Check Rule
resource "aws_config_config_rule" "root_account_mfa_enabled" {
  name = "nwm_root_account_mfa_enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#  ELB looging Check Rule
resource "aws_config_config_rule" "elb_logging_enabled" {
  name  = "nwm_elb_logging_enabled"

  source {
    owner             = "AWS"
    source_identifier = "ELB_LOGGING_ENABLED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#Required tags check Rule
resource "aws_config_config_rule" "required_tags_check" {
  name  = "nwm_required_tags_check"

  input_parameters = <<PARAMETERS
  {
    "tag1Key" : "Cost Center",
    "tag1Value" : "${data.consul_keys.standard.var.costcenter}",
    "tag2Key" : "Terraform",
    "tag2Value" : "Yes"
   }

PARAMETERS

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#EC2 volume in Use check Rule
resource "aws_config_config_rule" "ec2_volume_inuse_check" {
  name  = "nwm_ec2_volume_inuse_check"
  source {
    owner             = "AWS"
    source_identifier = "EC2_VOLUME_INUSE_CHECK"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#VPC flow logs enabled check Rule
resource "aws_config_config_rule" "vpc_flow_logs_enabled_check" {
  name  = "nwm_vpc_flow_logs_enabled_check"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}

#elb-logging-enabled check Rule
resource "aws_config_config_rule" "elb_logging_enabled_check" {
  name  = "nwm_elb_logging_enabled_check"

  source {
    owner             = "AWS"
    source_identifier = "ELB_LOGGING_ENABLED"
  }

  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}


