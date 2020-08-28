data "archive_file" "lambda_s3_log_copy_zip" {
  type        = "zip"
  source_file = "files/s3_log_copy.py"
  output_path = "files/s3_log_copy.zip"
}

resource "aws_lambda_function" "s3_log_copy" {
  filename         = "files/s3_log_copy.zip"
  function_name    = "s3_log_copy-${local.region}"
  role             = "${data.aws_iam_role.lambda-s3-log-copy.arn}"
  description      = "Copies S3 Access logs from one bucket to another"
  handler          = "s3_log_copy.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_s3_log_copy_zip.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 300
  environment {
    variables = {
      target_bucket = "logging-${local.account_alias_core[local.environment]}-s3access-${local.region}"
    }
  }
  tags = "${merge(local.default_tags, map(
    "Name", "s3_log_copy-${local.region}"
  ))}"
}

resource "aws_lambda_permission" "s3_log_copy" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.s3_log_copy.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.s3_access_log.arn}"
}

