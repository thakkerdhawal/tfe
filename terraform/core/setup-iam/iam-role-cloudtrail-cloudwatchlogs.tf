resource "aws_iam_role" "ct-cw-role" {
  count              = "${local.region == "eu-west-2" ? 1 : 0}"
  name               = "cloudtrail-cloudwatchlogs-role"
  description        = "Role for cloutrail to cloudwatch logs"
  assume_role_policy = "${data.aws_iam_policy_document.cloudtrail-assume-role-policy.json}"
  tags = "${merge(local.default_tags, map(
    "Name", "cloudtrail-cwlogs-role"
  ))}"
}

resource "aws_iam_role_policy" "ct-cwlogs-role-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "cloudtrail-to-cloudwatchlogs-policy"
  role = "${aws_iam_role.ct-cw-role.id}"
  policy = "${data.aws_iam_policy_document.ct-cwlogs-policy.json}"
}

data "aws_iam_policy_document" "ct-cwlogs-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
    ]
  }
}
