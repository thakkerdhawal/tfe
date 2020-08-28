data "aws_region" "current" {}
data "aws_iam_role" "s3-crr-role" { name = "s3-crr-role" }

locals { replica_region = "${data.aws_region.current.name == "eu-west-1" ? "eu-west-2" : "eu-west-1"}" }

##  Create and Configure Main Bucket
resource "aws_s3_bucket" "s3-bucket" {
  count = "${var.enabled ? 1 : 0}"
  bucket = "logging-${var.account_alias}-${var.name}-${var.global ? "global" : data.aws_region.current.name}"
  acl    = "private"
  lifecycle { prevent_destroy = true } 
  versioning { enabled = true }
  policy = "${data.aws_iam_policy_document.bucket-policy.json}"
  server_side_encryption_configuration {
     rule {
       apply_server_side_encryption_by_default {
       sse_algorithm = "AES256"
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
  replication_configuration {
    role = "${data.aws_iam_role.s3-crr-role.arn}"
    rules {
      id = "logging-bucket-replication-rule"
      status = "Enabled"
      destination {
        bucket        = "arn:aws:s3:::logging-${var.account_alias}-${var.name}-${var.global ? "global" : data.aws_region.current.name}-replica"
        storage_class = "STANDARD"
      }
    }
  }
  tags = "${merge(var.default_tags, map(
    "Name", "logging-${var.account_alias}-${var.name}-${var.global ? "global" : data.aws_region.current.name}"
  ))}"
}

resource "aws_s3_bucket_public_access_block" "s3-bucket-public-access-block" {
  count = "${var.enabled ? 1 : 0}"
  bucket = "${aws_s3_bucket.s3-bucket.id}"
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "s3-bucket-sqs" {
  count = "${var.enabled ? 1 : 0}"
  depends_on = ["aws_s3_bucket_public_access_block.s3-bucket-public-access-block"]
  bucket = "${aws_s3_bucket.s3-bucket.id}"
  queue {
    queue_arn     = "${var.logging-sqs-queue-arn}"
    events        = ["s3:ObjectCreated:*"]
  }
}

## Create and Configure Replica Bucket
resource "aws_s3_bucket" "s3-bucket-replica" {
  count = "${var.enabled ? 1 : 0}"
  provider = "aws.replica"
  bucket = "logging-${var.account_alias}-${var.name}-${var.global ? "global" : data.aws_region.current.name}-replica"
  acl    = "private"
  lifecycle { prevent_destroy = true } 
  versioning { enabled = true }
  policy = "${data.aws_iam_policy_document.replica-bucket-policy.json}"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
      }
    }
  }
  lifecycle_rule {
    id = "transition-lifecycle-rule"
    prefix = ""
    enabled = true
    transition {
      days = 7
      storage_class = "GLACIER"
    }
  }
  tags = "${merge(var.default_tags, map(
    "Name", "logging-${var.account_alias}-${var.name}-${var.global ? "global" : data.aws_region.current.name}-replica"
  ))}"
}

resource "aws_s3_bucket_public_access_block" "s3-bucket-public-access-block-replica" {
  count = "${var.enabled ? 1 : 0}"
  provider = "aws.replica"
  bucket = "${aws_s3_bucket.s3-bucket-replica.id}"
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}
