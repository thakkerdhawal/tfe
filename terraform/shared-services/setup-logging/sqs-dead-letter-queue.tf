resource "aws_sqs_queue" "logging-dead-letter-queue" {
  name                      = "logging-dead-letter-queue"
  # NOTE: the numbers are still experimental
  visibility_timeout_seconds = 120 # 2 mins
  message_retention_seconds = 604800  # 7 days
  receive_wait_time_seconds = 10
  tags = "${merge(local.default_tags, map(
    "Name", "logging-dead-letter-queue"
  ))}"
}

