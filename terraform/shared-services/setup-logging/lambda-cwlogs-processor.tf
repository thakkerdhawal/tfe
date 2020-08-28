data "archive_file" "cwlogs-processor" {
  type        = "zip"
  source_file = "${path.module}/files/kinesis-firehose-cloudwatch-logs-processor.js"
  output_path = "${path.module}/files/kinesis-firehose-cloudwatch-logs-processor.zip"
}

resource "aws_lambda_function" "cwlogs-processor" {
  filename         = "files/kinesis-firehose-cloudwatch-logs-processor.zip"
  function_name    = "${local.environment}-firehose-cwlogs-processor"
  role             = "${data.aws_iam_role.lambda-basic-role.arn}"
  handler          = "kinesis-firehose-cloudwatch-logs-processor.handler"
  source_code_hash = "${base64sha256(file(data.archive_file.cwlogs-processor.output_path))}"
  runtime          = "nodejs8.10"
  timeout          = "60"
  description      = "An Amazon Kinesis Firehose stream processor that extracts individual log events from records sent by Cloudwatch Logs subscription filters."
}
