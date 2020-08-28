data "aws_caller_identity" "current" {}

data "aws_iam_role" "lambda-s3-log-copy" {
  name = "lambda-s3-log-copy"
}

data "aws_iam_role" "lambda-basic-role" {
  name = "lambda-basic-role"
}
