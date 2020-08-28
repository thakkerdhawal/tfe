data "aws_iam_policy_document" "bucket-policy" {
  source_json = "${var.s3-bucket-policy-doc}"
  statement {
    effect = "Deny"
    sid = "block_insecure_http"
    actions   = ["*"]
    resources = ["arn:aws:s3:::logging-${var.account_alias}-${var.name}-${var.global ? "global" : data.aws_region.current.name}/*"]
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

data "aws_iam_policy_document" "replica-bucket-policy" {
  statement {
    effect = "Deny"
    sid = "block_insecure_http"
    actions   = ["*"]
    resources = ["arn:aws:s3:::logging-${var.account_alias}-${var.name}-${var.global ? "global" : data.aws_region.current.name}-replica/*"]
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
