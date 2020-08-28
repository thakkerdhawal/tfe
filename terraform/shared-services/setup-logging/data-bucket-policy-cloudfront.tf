#Applying bucket policy
# SS-Main bucket
data "aws_iam_policy_document" "s3-cloudfront-policy-doc-ss" {
  # Permission required for Cloudfront
  statement {
    effect = "Allow"
    actions   = ["s3:GetBucketAcl","s3:PutBucketAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_shared-services[local.environment]}-cloudfront-global"]
    principals {
      type        = "AWS"
      identifiers = ["${local.account_number_shared-services[local.environment]}"]
    }
  }
}
# Core-Main bucket
data "aws_iam_policy_document" "s3-cloudfront-policy-doc-core" {
  # Permission required for Cloudfront
  statement {
    effect = "Allow"
    actions   = ["s3:GetBucketAcl","s3:PutBucketAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-cloudfront-global"]
    principals {
      type        = "AWS"
      identifiers = ["${local.account_number_core[local.environment]}"]
    }
  }
}

# NonProd Core-Main bucket
data "aws_iam_policy_document" "s3-cloudfront-policy-doc-core-nonprod" {
  # Permission required for Cloudfront
  statement {
    effect = "Allow"
    actions   = ["s3:GetBucketAcl","s3:PutBucketAcl"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core["nonprod"]}-cloudfront-global"]
    principals {
      type        = "AWS"
      identifiers = ["${local.account_number_core["nonprod"]}"]
    }
  }
}

