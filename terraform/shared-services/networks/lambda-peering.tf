data "archive_file" "create_route_table_entry" {
  type        = "zip"
  source_file = "${path.module}/files/create_route_table_entry.py"
  output_path = "${path.module}/files/create_route_table_entry.zip"
}

resource "aws_lambda_function" "route_lambda" {
  filename         = "files/create_route_table_entry.zip"
  function_name    = "${local.environment}-create_route_table_entry"
  role             = "arn:aws:iam::${local.account_number_shared-services[local.environment]}:role/vpc_peering-lambda-execution"
  handler          = "create_route_table_entry.lambda_handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.create_route_table_entry.output_path}"))}"
  runtime          = "python3.6"
  timeout          = "10"
  description      = "lambda function to manage routing for peering connection"
}

resource "aws_lambda_permission" "allow_execution" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.route_lambda.function_name}"
  principal     = "arn:aws:iam::${local.account_number_shared-services[local.environment]}:root"
}
