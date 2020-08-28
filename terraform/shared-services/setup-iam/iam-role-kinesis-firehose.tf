resource "aws_iam_role" "kinesis-firehose-role" {
  count              = "${local.region == "eu-west-2" ? 1 : 0}"
  name               = "kinesis-firehose-role"
  description        = "Role for AWS Kinesis Firehose"
  assume_role_policy = "${data.aws_iam_policy_document.firehose-assume-role-policy.json}"
  tags = "${merge(local.default_tags, map(
    "Name", "kinesis-firehose-role"
  ))}"
}

resource "aws_iam_role_policy" "kinesis-firehose-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "kinesis-firehose-policy"
  role = "${aws_iam_role.kinesis-firehose-role.id}"
  policy = "${data.aws_iam_policy_document.kinesis-firehose-policy.json}"
}

data "aws_iam_policy_document" "kinesis-firehose-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    effect = "Allow"
    actions = [
          "s3:AbortMultipartUpload",        
          "s3:GetBucketLocation",        
          "s3:GetObject",        
          "s3:ListBucket",        
          "s3:ListBucketMultipartUploads",        
          "s3:PutObjectAcl",
          "s3:PutObject"
    ]
    resources = [
          "arn:aws:s3:::logging-${data.aws_iam_account_alias.current.account_alias}-cloudwatch-eu-west-1",
          "arn:aws:s3:::logging-${data.aws_iam_account_alias.current.account_alias}-cloudwatch-eu-west-1/*",
          "arn:aws:s3:::logging-${data.aws_iam_account_alias.current.account_alias}-cloudwatch-eu-west-2",
          "arn:aws:s3:::logging-${data.aws_iam_account_alias.current.account_alias}-cloudwatch-eu-west-2/*",
          "arn:aws:s3:::logging-${data.aws_iam_account_alias.current.account_alias}-waf-eu-west-1",
          "arn:aws:s3:::logging-${data.aws_iam_account_alias.current.account_alias}-waf-eu-west-1/*",
          "arn:aws:s3:::logging-${data.aws_iam_account_alias.current.account_alias}-waf-eu-west-2",
          "arn:aws:s3:::logging-${data.aws_iam_account_alias.current.account_alias}-waf-eu-west-2/*"
    ]
  },
  statement {
    effect = "Allow"
    actions = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
    ]
    resources = [
          "arn:aws:lambda:eu-west-1:${data.aws_caller_identity.current.account_id}:function:${local.environment}-firehose-cwlogs-processor",
          "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.current.account_id}:function:${local.environment}-firehose-cwlogs-processor"
    ]
  },
  statement {
    effect = "Allow"
    actions = [
         "logs:PutLogEvents",
    ]
    resources = [
          "arn:aws:logs:eu-west-1:${data.aws_caller_identity.current.account_id}:log-group:firehose-s3-delivery-error-loggroup:log-stream:firehose-s3-delivery-error", 
          "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:firehose-s3-delivery-error-loggroup:log-stream:firehose-s3-delivery-error" 
    ]
  },
  statement {
    effect = "Allow"
    actions = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords"
    ]
    resources = [
          "arn:aws:kinesis:eu-west-1:${data.aws_caller_identity.current.account_id}:stream/*",
          "arn:aws:kinesis:eu-west-2:${data.aws_caller_identity.current.account_id}:stream/*"
    ]
  }
}
