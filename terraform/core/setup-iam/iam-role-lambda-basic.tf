# Role for lambda function so that does not require extra permissions

resource "aws_iam_role" "lambda-basic-role" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "lambda-basic-role"
  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
}

resource "aws_iam_role_policy_attachment" "lambda-basic-role" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.lambda-basic-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
