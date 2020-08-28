resource "aws_iam_role" "lambda-s3-log-copy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "lambda-s3-log-copy"
  description = "Role for S3 Access Log copy Lambda function"
  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
  tags = "${merge(local.default_tags, map(
    "Name", "lambda-s3-log-copy"
  ))}"
}

resource "aws_iam_role_policy" "lambda-s3-log-copy_policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "lambda-s3-log-copy_policy"
  role = "${aws_iam_role.lambda-s3-log-copy.id}"
  policy = "${data.aws_iam_policy_document.lambda-s3-log-copy_policy.json}"
}

data "aws_iam_policy_document" "lambda-s3-log-copy_policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
    ]
  }
}

