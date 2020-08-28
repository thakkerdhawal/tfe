# Role for core account to assume role so that they can invoke lambda function 
resource "aws_iam_role" "core_assume" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "core_assume"

  assume_role_policy = "${data.aws_iam_policy_document.core_assume-role-policy.json}"
}

resource "aws_iam_policy" "core_assume" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  name   = "core_assume"
  path   = "/"
  policy = "${data.aws_iam_policy_document.core_assume.json}"
}

resource "aws_iam_role_policy_attachment" "core_assume" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.core_assume.name}"
  policy_arn = "${aws_iam_policy.core_assume.arn}"
}
