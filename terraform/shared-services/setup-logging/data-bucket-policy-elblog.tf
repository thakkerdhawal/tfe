#Applying bucket policy
# SS-Main bucket
data "aws_iam_policy_document" "s3-elblog-policy-doc-ss" {
  # Permission required for ALB
  statement {
    effect = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_shared-services[local.environment]}-elblog-${local.region}/*"]
    principals {
      type        = "AWS"
      identifiers = ["${local.aws_elb_account_number[local.region]}"]
    }
  }
  # Permission required for NLB
  statement {
    effect = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_shared-services[local.environment]}-elblog-${local.region}"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
  statement {
    effect = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_shared-services[local.environment]}-elblog-${local.region}/*"]
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
data "aws_iam_policy_document" "s3-elblog-policy-doc-core" {
  # Permission required for ALB
  statement {
    effect = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-elblog-${local.region}/*"]
    principals {
      type        = "AWS"
      identifiers = ["${local.aws_elb_account_number[local.region]}"]
    }
  }
  # Permission required for NLB
  statement {
    effect = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-elblog-${local.region}"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
  statement {
    effect = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-elblog-${local.region}/*"]
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
data "aws_iam_policy_document" "s3-elblog-policy-doc-core-nonprod" {
  # Permission required for ALB
  statement {
    effect = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-elblog-${local.region}/*"]
    principals {
      type        = "AWS"
      identifiers = ["${local.aws_elb_account_number[local.region]}"]
    }
  }
  # Permission required for NLB
  statement {
    effect = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-elblog-${local.region}"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
  statement {
    effect = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-elblog-${local.region}/*"]
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

