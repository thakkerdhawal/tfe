#Role for lambda function so that it can add ip targets to targetgroup

resource "aws_iam_role" "mgmt-alb-role" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "mgmt-alb-lambda-execution"

  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
}

resource "aws_iam_policy" "mgmt-alb-lambda-execution-policy" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  name   = "mgmt-alb-lambda-execution-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.mgmt-alb-lambda-execution-policy.json}"
}

resource "aws_iam_role_policy_attachment" "mgmt-alb-exec-role" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.mgmt-alb-role.name}"
  policy_arn = "${aws_iam_policy.mgmt-alb-lambda-execution-policy.arn}"
}
