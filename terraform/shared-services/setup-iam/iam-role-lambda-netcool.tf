resource "aws_iam_role" "netcool-lambda-role" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  name       = "netcool-lambda-iam-role"
  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
}


data "aws_iam_policy_document" "netcool-lambda-execution-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    effect = "Allow"
    resources = ["*"]
    sid= "netcoollambdaaccess",
    actions = [
	 "logs:CreateLogGroup",
         "logs:CreateLogStream",
         "logs:PutLogEvents",
         "logs:DescribeLogStreams",
         "logs:DescribeLogGroups",
 	 "ec2:CreateNetworkInterface",
         "ec2:DescribeNetworkInterfaces",
         "ec2:DeleteNetworkInterface"
    ]
  }
}

resource "aws_iam_policy" "netcool-lambda-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name        = "netcool-lambda-iam-policy"
  description = "${local.environment}-netcool-lambda-iam-policy"
  policy = "${data.aws_iam_policy_document.netcool-lambda-execution-policy.json}"
}

resource "aws_iam_role_policy_attachment" "netcool-lambda-access-attach" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.netcool-lambda-role.name}"
  policy_arn = "${aws_iam_policy.netcool-lambda-policy.arn}"
}
