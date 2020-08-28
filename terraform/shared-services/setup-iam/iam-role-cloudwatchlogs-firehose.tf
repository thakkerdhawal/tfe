resource "aws_iam_role" "cloudwatchlogs-to-firehose-role" {
  count              = "${local.region == "eu-west-2" ? 1 : 0}"
  name               = "cloudwatchlogs-to-firehose-role"
  description        = "Role for CWL to Firehose"
  assume_role_policy = "${data.aws_iam_policy_document.cloudwatchlogs-assume-role-policy.json}"
  tags = "${merge(local.default_tags, map(
    "Name", "cloudwatchlogs-to-firehose-role"
  ))}"
}

resource "aws_iam_role_policy" "cloudwatchlogs-to-firehose-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "cloudwatchlogs-to-firehose-policy"
  role = "${aws_iam_role.cloudwatchlogs-to-firehose-role.id}"
  policy = "${data.aws_iam_policy_document.cloudwatchlogs-to-firehose-policy.json}"
}

data "aws_iam_policy_document" "cloudwatchlogs-to-firehose-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    effect = "Allow"
    resources = ["arn:aws:firehose:*"]
    actions = ["firehose:*"]
  }
  statement {
    effect = "Allow"
    resources = ["${aws_iam_role.cloudwatchlogs-to-firehose-role.arn}"]
    actions = ["iam:PassRole"]
  }
}
