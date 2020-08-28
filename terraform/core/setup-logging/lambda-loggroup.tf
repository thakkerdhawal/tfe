data "archive_file" "loggroup-policy" {
  type        = "zip"
  source_file = "${path.module}/files/manageLogGroup.py"
  output_path = "${path.module}/files/manageLogGroup.zip"
}

resource "aws_lambda_function" "loggroup-policy" {
  filename         = "files/manageLogGroup.zip"
  function_name    = "${local.environment}-loggroup-policy"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/manage-logs-lambda-execution"
  handler          = "manageLogGroup.lambda_handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.loggroup-policy.output_path}"))}"
  runtime          = "python3.6"
  timeout          = "900"
  environment {
    variables = {
      cwlogs_processor_arn = "${aws_lambda_function.cwlogs-processor.arn}"
    }
  }
  description      = "lambda function to set policy on log groups"
}

resource "aws_lambda_permission" "loggroup-policy_allow_execution" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.loggroup-policy.function_name}"
  principal     = "events.amazonaws.com"
  source_arn     = "${aws_cloudwatch_event_rule.everyday.arn}"
}

resource "aws_cloudwatch_event_rule" "everyday" {
  name = "${local.environment}-everyday"
  description = "Fires everyday"
  schedule_expression = "cron(0 8 ? * * *)"
}

resource "aws_cloudwatch_event_target" "check-loggroup-policy-everyday" {
  rule = "${aws_cloudwatch_event_rule.everyday.name}"
  arn = "${aws_lambda_function.loggroup-policy.arn}"
}
