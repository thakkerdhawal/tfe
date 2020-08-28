#Applying bucket policy
# SS-Main bucket
data "aws_iam_policy_document" "s3-vpcflow-policy-doc-ss" {
  statement {
    effect = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_shared-services[local.environment]}-vpcflow-${local.region}"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
  statement {
    effect = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_shared-services[local.environment]}-vpcflow-${local.region}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}
# Core-Main bucket
data "aws_iam_policy_document" "s3-vpcflow-policy-doc-core" {
  statement {
    effect = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-vpcflow-${local.region}"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
  statement {
    effect = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-vpcflow-${local.region}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}

# NonProd Core-Main bucket
data "aws_iam_policy_document" "s3-vpcflow-policy-doc-core-nonprod" {
  statement {
    effect = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-vpcflow-${local.region}"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
  statement {
    effect = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-vpcflow-${local.region}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}

