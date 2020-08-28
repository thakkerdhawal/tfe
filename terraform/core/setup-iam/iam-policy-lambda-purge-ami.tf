
data "aws_iam_policy_document" "purge-ami-lambda-execution-policy" {
  statement {
    actions = [
       "ec2:DescribeInstances", 
       "ec2:DescribeImages",
       "ec2:DescribeTags",  
       "ec2:DescribeSnapshots",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    resources = ["*"]
    sid= "purgeamilambdaaccess",
    actions = [
      	 "logs:CreateLogGroup",
         "logs:CreateLogStream",
         "logs:PutLogEvents",
         "logs:DescribeLogStreams",
         "logs:DescribeLogGroups"
    ]
  }
}
