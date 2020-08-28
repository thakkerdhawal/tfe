data "archive_file" "netcool-lambda-zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_netcool_files.zip"
  source_dir  = "${path.module}/lambda_netcool_files"
}

resource "aws_lambda_function" "netcool-lambda" {
  filename         = "lambda_netcool_files.zip"
  function_name    = "${local.environment}-netcool-data"
  role             = "${data.aws_iam_role.netcool-lambda-role.arn}"
  handler          = "netcool-lambda.lambda_handler"
  source_code_hash = "${data.archive_file.netcool-lambda-zip.output_base64sha256}"
  runtime          = "python2.7"
  description      = "Function to generate  CloudWatch log entries to trigger the SNS --> Netcool workflow"
  timeout          = "30"
  environment {
    variables = {
      netcool_ip   = "${element(split("/",data.consul_keys.netcool.var.netcool_ip),0)}"
    }
  }
  vpc_config {
    security_group_ids = ["${aws_security_group.netcool-lambda-sg.id}"]
    subnet_ids         = ["${module.vpcss.intra_subnets}"]
  }
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-netcool-data"
  ))}"
}

resource "aws_lambda_permission" "netcool-sns-lambda-perm" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.netcool-lambda.arn}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${data.aws_sns_topic.netcool-sns.arn}"
}
