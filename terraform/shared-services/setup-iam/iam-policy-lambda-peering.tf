
data "aws_iam_policy_document" "vpc_peering-lambda-execution-policy" {
  statement {
    actions = [
      "ec2:CreateRoute",
      "ec2:ReplaceRoute",
    ]

    resources = [
        "arn:aws:ec2:eu-west-1:${local.account_number_shared-services[local.environment]}:route-table/*",
        "arn:aws:ec2:eu-west-2:${local.account_number_shared-services[local.environment]}:route-table/*",
    ]
  }

  statement {
    actions = [
      "ec2:DescribeRouteTables",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    resources = ["*"]
    sid= "vpcpeeringlambdaaccess",
    actions = [
         "logs:CreateLogGroup",
         "logs:CreateLogStream",
         "logs:PutLogEvents",
         "logs:DescribeLogStreams",
         "logs:DescribeLogGroups"
    ]
  }
}
