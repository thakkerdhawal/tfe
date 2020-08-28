# Role for lambda function to operate on peering
resource "aws_iam_role" "iam_for_lambda" {
  count              = "${local.region == "eu-west-2" ? 1 : 0}"
  name               = "vpc_peering-lambda-execution"

  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
}

resource "aws_iam_policy" "vpc_peering-lambda-execution-policy" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  name   = "vpc_peering-lambda-execution-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.vpc_peering-lambda-execution-policy.json}"
}

resource "aws_iam_role_policy_attachment" "basic-exec-role" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.vpc_peering-lambda-execution-policy.arn}"
}
