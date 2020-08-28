

data "aws_sns_topic" "netcool-sns" {
  name = "${local.environment}-netcool-sns-topic"
}

data "aws_iam_role" "netcool-lambda-role" {
  name = "netcool-lambda-iam-role"
}
