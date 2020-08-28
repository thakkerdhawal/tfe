
data "aws_iam_policy_document" "manage-logs-lambda-execution-policy" {
  statement {
    actions = [
      "firehose:DescribeDeliveryStream",
      "logs:PutSubscriptionFilter",
      "logs:PutRetentionPolicy",
      "iam:PassRole",
      "firehose:CreateDeliveryStream",
    ]

    resources = [
        "arn:aws:firehose:eu-west-2:${local.account_number_core[local.environment]}:deliverystream/*",
        "arn:aws:logs:eu-west-2:${local.account_number_core[local.environment]}:log-group:*:log-stream:",
        "arn:aws:firehose:eu-west-1:${local.account_number_core[local.environment]}:deliverystream/*",
        "arn:aws:logs:eu-west-1:${local.account_number_core[local.environment]}:log-group:*:log-stream:",
        "arn:aws:iam::${local.account_number_core[local.environment]}:role/cloudwatchlogs-to-firehose-role",
        "arn:aws:iam::${local.account_number_core[local.environment]}:role/kinesis-firehose-role",
    ]
  }

  statement {
    actions = [
      "iam:ListAccountAliases",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    resources = ["*"]
    sid= "mgmtlogslambdaaccess",
    actions = [
      	 "logs:CreateLogGroup",
         "logs:CreateLogStream",
         "logs:PutLogEvents",
         "logs:DescribeLogStreams",
         "logs:DescribeLogGroups"
    ]
  }
}
