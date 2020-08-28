resource "aws_s3_bucket" "stream_binary_log" {
  bucket = "logging-${local.account_alias_core[local.environment]}-stream-binary-${local.region}"
  acl = "private"
  lifecycle { prevent_destroy = true } 
  versioning { enabled = true }
  policy = "${data.aws_iam_policy_document.s3-logging-stream-binary.json}"
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
      days = 183
    }
    noncurrent_version_expiration {
      days = 183
    }
  }

  tags = "${merge(local.default_tags, map(
    "Name", "logging-${local.account_alias_core[local.environment]}-stream-binary-${local.region}"
  ))}"
}

resource "aws_s3_bucket_public_access_block" "stream_binary_log" {
  bucket = "${aws_s3_bucket.stream_binary_log.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

