data "aws_region" "current" {}
# data "aws_sqs_queue" "logging-dead-letter-queue" { name = "logging-dead-letter-queue" }

# Create a SQS queue for all S3 access logging buckets in this region
resource "aws_sqs_queue" "logging-sqs-queue" {
  name                      = "logging-${var.name}-queue"
  # NOTE: the numbers are still experimental
  visibility_timeout_seconds = 600  # 10 mins
  message_retention_seconds = 604800    # 7 days 
  receive_wait_time_seconds = 10
  redrive_policy            = "{\"deadLetterTargetArn\":\"${var.logging-dead-letter-queue-arn}\",\"maxReceiveCount\":3}"
  tags = "${merge(var.default_tags, map(
    "Name", "logging-${var.name}-queue"
  ))}"
}

data "aws_iam_policy_document" "sqs-queue-policy-doc" {
  statement {
    effect = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = ["${aws_sqs_queue.logging-sqs-queue.arn}"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    condition {
      test     = "ForAnyValue:ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:s3:::logging-*-${var.name}-${var.global ? "global" : data.aws_region.current.name}"]
    }
  }
}

resource "aws_sqs_queue_policy" "logging-sqs-queue-policy" {
  queue_url = "${aws_sqs_queue.logging-sqs-queue.id}"
  policy = "${data.aws_iam_policy_document.sqs-queue-policy-doc.json}"
}
