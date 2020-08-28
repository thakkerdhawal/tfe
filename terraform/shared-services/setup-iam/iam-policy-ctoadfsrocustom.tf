
resource "aws_iam_policy" "ctoadfsrocustom" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "ctoadfsrocustom"
  description = "Read Only policy for CTO Access"
  policy = "${data.aws_iam_policy_document.ctoadfsrocustom.json}"
}

data "aws_iam_policy_document" "ctoadfsrocustom" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    effect = "Allow"
    sid = "ctoadfsrocustom"
    resources = ["*"]
    actions = [
          "sns:List*",
          "sns:Get*",
          "logs:Test*",
          "logs:List*",
          "logs:Get*",
          "logs:FilterLogEvents",
          "logs:Describe*",
          "iam:List*",
          "iam:Get*",
          "iam:Describe*",
          "guardduty:List*",
          "guardduty:Get*",
          "events:Test*",
          "events:List*",
          "events:Get*",
          "events:Describe*",
          "cloudwatch:List*",
          "cloudwatch:Get*",
          "cloudwatch:Describe*",
          "autoscaling:Describe*"
    ]
  }
}

