# SS-Main bucket policy
data "aws_iam_policy_document" "s3-waf-policy-doc-ss" {
  statement {
    effect = "Allow"
    actions   = ["*"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_shared-services[local.environment]}-waf-${local.region}",
                 "arn:aws:s3:::logging-${local.account_alias_shared-services[local.environment]}-waf-${local.region}/*"]
    principals {
      type        = "AWS"
      identifiers = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
}

# Core-Main bucket
data "aws_iam_policy_document" "s3-waf-policy-doc-core" {
  statement {
    effect = "Allow"
    actions   = ["s3:ListBucket","s3:GetObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-waf-${local.region}",
                 "arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-waf-${local.region}/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_number_core[local.environment]}:role/kinesis-firehose-role"]
    }
  }
  statement {
    effect = "Allow"
   actions   = ["s3:PutObject","s3:PutObjectAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-waf-${local.region}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_number_core[local.environment]}:role/kinesis-firehose-role"]
    }
  }
}

# NonProd Core-Main bucket
data "aws_iam_policy_document" "s3-waf-policy-doc-core-nonprod" {
 statement {
    effect = "Allow"
    actions   = ["s3:ListBucket","s3:GetObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-waf-${local.region}",
                 "arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-waf-${local.region}/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_number_core["nonprod"]}:role/kinesis-firehose-role"]
    }
  }
  statement {
    effect = "Allow"
   actions   = ["s3:PutObject","s3:PutObjectAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-waf-${local.region}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_number_core["nonprod"]}:role/kinesis-firehose-role"]
    }
  }
}

