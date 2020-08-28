data "archive_file" "lambda_shield_advanced_zip" {
  count       = "${local.region == "eu-west-2" ? 1 : 0}"
  type        = "zip"
  source_file = "files/enable_advanced_shield.py"
  output_path = "files/enable_advanced_shield.zip"
}

resource "aws_lambda_function" "enable_advanced_shield" {
  count            = "${local.region == "eu-west-2" ? 1 : 0}"
  filename         = "files/enable_advanced_shield.zip"
  function_name    = "${local.environment}_enable_advanced_shield"
  role             = "${data.aws_iam_role.lambda_shield_execution.arn}"
  description      = "Enables advanced shield and adds protection resources"
  handler          = "enable_advanced_shield.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_shield_advanced_zip.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 120
  environment {
    variables = {
      shield_notification_email = "${data.consul_keys.shield.var.shield_notification_email}"
      shield_drt_buckets = "${local.shield_drt_buckets}"
    }
  }

  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}_enable_advanced_shield"
  ))}"
}

resource "aws_cloudwatch_event_rule" "enable_advanced_shield" {
  count               = "${local.region == "eu-west-2" ? 1 : 0}"
  name                = "${local.environment}_update_advanced_shield_protected_resources"
  description         = "Trigger Lambda function at 1am Everyday"
  schedule_expression = "cron(0 1 ? * * *)"
}

resource "aws_cloudwatch_event_target" "enable_advanced_shield" {
  count     = "${local.region == "eu-west-2" ? 1 : 0}"
  rule      = "${aws_cloudwatch_event_rule.enable_advanced_shield.name}"
  arn       = "${aws_lambda_function.enable_advanced_shield.arn}"
}

resource "aws_lambda_permission" "enable_advanced_shield" {
  count         = "${local.region == "eu-west-2" ? 1 : 0}"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.enable_advanced_shield.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.enable_advanced_shield.arn}"
}

