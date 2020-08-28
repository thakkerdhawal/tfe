# Streaming Rates Binary logs S3 bucket policy
data "aws_iam_policy_document" "s3-logging-stream-binary" {
  statement {
    effect = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-stream-binary-${local.region}/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_number_core[local.environment]}:role/ec2-default-role"]
    }
  }

  statement {
    effect = "Deny"
    actions   = ["*"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-stream-binary-${local.region}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = ["false"]
    }
  }
}
