resource "aws_cloudwatch_log_group" "firehose-s3-delivery-error-loggroup" {
  name = "firehose-s3-delivery-error-loggroup"
  retention_in_days = "90"
}

resource "aws_cloudwatch_log_stream" "firehose-s3-delivery-error" {
  name           = "firehose-s3-delivery-error"
  log_group_name = "${aws_cloudwatch_log_group.firehose-s3-delivery-error-loggroup.name}"
}
