#Role for lambda function to purge ami and general housekeeping of ami 

resource "aws_iam_role" "purge-ami-role" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "purge-ami-lambda-execution"

  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
}

resource "aws_iam_policy" "purge-ami-lambda-execution-policy" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  name   = "purge-ami-lambda-execution-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.purge-ami-lambda-execution-policy.json}"
}

resource "aws_iam_role_policy_attachment" "purge-ami-exec-role" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.purge-ami-role.name}"
  policy_arn = "${aws_iam_policy.purge-ami-lambda-execution-policy.arn}"
}
