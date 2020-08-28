data "aws_iam_policy_document" "s3-access-log" {
  statement {
    effect = "Deny"
    actions   = ["*"]
    resources = ["arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-s3-staging-${local.region}/*"]
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
