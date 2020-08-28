#Role for lambda function so that it can manage log groups and firehose stream 

resource "aws_iam_role" "manage-logs-role" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "manage-logs-lambda-execution"

  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
}

resource "aws_iam_policy" "manage-logs-lambda-execution-policy" {
  count  = "${local.region == "eu-west-2" ? 1 : 0}"
  name   = "manage-logs-lambda-execution-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.manage-logs-lambda-execution-policy.json}"
}

resource "aws_iam_role_policy_attachment" "manage-logs-exec-role" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.manage-logs-role.name}"
  policy_arn = "${aws_iam_policy.manage-logs-lambda-execution-policy.arn}"
}
