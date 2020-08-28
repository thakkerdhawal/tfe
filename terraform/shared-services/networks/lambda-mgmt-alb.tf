data "archive_file" "add-instance-to-mgmt-alb" {
  type        = "zip"
  source_file = "${path.module}/files/add-instance-to-mgmt-alb.py"
  output_path = "${path.module}/files/add-instance-to-mgmt-alb.zip"
}

resource "aws_lambda_function" "mgmt-alb" {
  filename         = "files/add-instance-to-mgmt-alb.zip"
  function_name    = "${local.environment}-add-instance-to-mgmt-alb"
  role             = "arn:aws:iam::${local.account_number_shared-services[local.environment]}:role/mgmt-alb-lambda-execution"
  handler          = "add-instance-to-mgmt-alb.lambda_handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.add-instance-to-mgmt-alb.output_path}"))}"
  runtime          = "python3.6"
  timeout          = "10"
  description      = "lambda function to add core aws instance to mgmt-alb"
}

resource "aws_lambda_permission" "mgmt-alb_allow_execution" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.mgmt-alb.function_name}"
  principal     = "arn:aws:iam::${local.account_number_shared-services[local.environment]}:root"
}
