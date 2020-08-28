
data "aws_iam_policy_document" "mgmt-alb-lambda-execution-policy" {
  statement {
    actions = [
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:RegisterTargets",
    ]

    resources = [
        "arn:aws:elasticloadbalancing:eu-west-1:${local.account_number_shared-services[local.environment]}:targetgroup/*",
        "arn:aws:elasticloadbalancing:eu-west-2:${local.account_number_shared-services[local.environment]}:targetgroup/*",
    ]
  }

  statement {
    actions = [
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTargetGroups",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    resources = ["*"]
    sid= "mgmtalblambdaaccess",
    actions = [
	 "logs:CreateLogGroup",
         "logs:CreateLogStream",
         "logs:PutLogEvents",
         "logs:DescribeLogStreams",
         "logs:DescribeLogGroups"
    ]
  }
}
