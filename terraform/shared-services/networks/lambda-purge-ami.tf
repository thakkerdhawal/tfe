data "archive_file" "purge-ami" {
  type        = "zip"
  source_file = "${path.module}/files/purge-ami.py"
  output_path = "${path.module}/files/purge-ami.zip"
}

resource "aws_lambda_function" "purge-ami" {
  filename         = "files/purge-ami.zip"
  function_name    = "${local.environment}-purge-ami"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/purge-ami-lambda-execution"
  handler          = "purge-ami.lambda_handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.purge-ami.output_path}"))}"
  runtime          = "python3.6"
  timeout          = "10"
  description      = "lambda function to purge ami"
}

resource "aws_lambda_permission" "purge-ami_allow_execution" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.purge-ami.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.purge-ami.arn}"
}

resource "aws_cloudwatch_event_rule" "purge-ami" {
  name = "${local.environment}-everyday"
  description = "Fires every month"
  schedule_expression = "cron(0 8 1 * ? *)"
}

resource "aws_cloudwatch_event_target" "purge-ami" {
  rule = "${aws_cloudwatch_event_rule.purge-ami.name}"
  arn = "${aws_lambda_function.purge-ami.arn}"
}
