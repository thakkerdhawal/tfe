resource "aws_s3_bucket" "s3_access_log" {
  bucket = "logging-${local.account_alias_core[local.environment]}-s3-staging-${local.region}"
  acl = "log-delivery-write"
  lifecycle { prevent_destroy = true } 
  versioning { enabled = true }
  policy = "${data.aws_iam_policy_document.s3-access-log.json}"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
  lifecycle_rule {
    id = "expiry-and-deletion-lifecycle-rule"
    enabled = true
    expiration {
      days = 7
    }
    noncurrent_version_expiration {
      days = 7
    }
  }

  tags = "${merge(local.default_tags, map(
    "Name", "${local.account_alias_core[local.environment]}-s3bucket-access-logs-staging-${local.region}"
  ))}"
}

resource "aws_s3_bucket_notification" "s3_access_log" {
  bucket = "${aws_s3_bucket.s3_access_log.id}"

  depends_on =["aws_s3_bucket_public_access_block.s3_access_log"]

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.s3_log_copy.arn}"
    events              = ["s3:ObjectCreated:*"]
    # TODO Determine if we need a filter
    #filter_prefix       = "AWSLogs/"
    #filter_suffix       = ".log"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access_log" {
  bucket = "${aws_s3_bucket.s3_access_log.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

