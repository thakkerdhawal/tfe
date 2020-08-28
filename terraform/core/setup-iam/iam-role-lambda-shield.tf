resource "aws_iam_role" "lambda_shield_execution" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "lambda_shield_execution"
  description = "Role for Shield Advanced Lambda function"
  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
  tags = "${merge(local.default_tags, map(
    "Name", "lambda_shield_execution"
  ))}"
}

resource "aws_iam_role_policy" "lambda_shield_execution_policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "lambda_shield_execution_policy"
  role = "${aws_iam_role.lambda_shield_execution.id}"
  policy = "${data.aws_iam_policy_document.lambda_shield_execution_policy.json}"
}

data "aws_iam_policy_document" "lambda_shield_execution_policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:DescribeAddresses",
          "elasticloadbalancing:DescribeLoadBalancers",
          "route53:ListHostedZones",
          "route53:GetHostedZone",
          "cloudfront:ListDistributions",
          "cloudfront:GetDistribution",
          "shield:*"
    ]
  }
  statement {
    effect = "Allow"
    resources = ["arn:aws:iam::${local.account_number_core[local.environment]}:role/aws-shield-drt-access"]
    actions = [
          "iam:PassRole", 
          "iam:ListAttachedRolePolicies", 
          "iam:GetRole"
    ]
  }
}
