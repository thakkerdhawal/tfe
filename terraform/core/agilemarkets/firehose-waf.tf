data "aws_iam_role" "kinesis-firehose-role" {
  name = "kinesis-firehose-role"
}

resource "aws_kinesis_firehose_delivery_stream" "kinesis-firehose-waf-regional-logs" {
  name        = "aws-waf-logs-${local.environment}-alb-${local.region}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = "${data.aws_iam_role.kinesis-firehose-role.arn}"
    bucket_arn = "arn:aws:s3:::logging-${local.account_alias_core[local.environment]}-waf-${local.region}"
    # TODO - Update to a saner buffer interval, set to 60 seconds for testing only
    buffer_interval = 60
    cloudwatch_logging_options {
      enabled = true
      log_group_name = "firehose-s3-delivery-error-loggroup"
      log_stream_name = "firehose-s3-delivery-error"
    }
  }

  tags = "${merge(local.default_tags, map(
    "Name", "aws-waf-logs-${local.environment}-alb-${local.region}"
  ))}"
}


