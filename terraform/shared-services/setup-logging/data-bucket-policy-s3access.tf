# SS-Main bucket policy 
data "aws_iam_policy_document" "s3-s3access-policy-doc-ss" { 
  statement {
    effect = "Allow"
    actions   = ["*"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_shared-services[local.environment]}-s3access-${local.region}",
                 "arn:aws:s3:::logging-${local.account_alias_shared-services[local.environment]}-s3access-${local.region}/*"]
    principals {
      type        = "AWS"
      identifiers = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
}
 
# Core-Main bucket policy
data "aws_iam_policy_document" "s3-s3access-policy-doc-core" {
  statement {
    effect = "Allow"
    actions   = ["s3:ListBucket","s3:GetObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-s3access-${local.region}",
                 "arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-s3access-${local.region}/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_number_core[local.environment]}:role/lambda-s3-log-copy"]
    }
  }
  statement {
    effect = "Allow"
   actions   = ["s3:PutObject","s3:PutObjectAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-s3access-${local.region}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_number_core[local.environment]}:role/lambda-s3-log-copy"]
    }
  }
}

# NonProd Core-Main bucket policy
data "aws_iam_policy_document" "s3-s3access-policy-doc-core-nonprod" {
 statement {
    effect = "Allow"
    actions   = ["s3:ListBucket","s3:GetObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-s3access-${local.region}",
                 "arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-s3access-${local.region}/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_number_core["nonprod"]}:role/lambda-s3-log-copy"]
    }
  }
  statement {
    effect = "Allow"
   actions   = ["s3:PutObject","s3:PutObjectAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-s3access-${local.region}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_number_core["nonprod"]}:role/lambda-s3-log-copy"]
    }
  }
}

