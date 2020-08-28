data "aws_caller_identity" "current" {}

data "aws_iam_role" "s3-crr-role" {
  name = "s3-crr-role"
}

data "aws_iam_role" "lambda-basic-role" {
  name = "lambda-basic-role"
}
