locals {
  aws_managed_policy_for_ec2-splunkforwarder-role = ["CloudWatchAgentServerPolicy"]
}

data "aws_iam_policy_document" "ec2-splunkforwarder-role-policy-doc" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    sid = "S3Access"
    effect = "Allow"
    resources = ["arn:aws:s3:::logging-*", "arn:aws:s3:::logging-*/*"]
    actions = [
      "s3:ListBucket",
      "s3:ListAllMyBuckets",
      "s3:GetObject",
      "kms:Decrypt"
    ]
  }
  statement {
    sid = "SQSListQueue"
    effect = "Allow"
    resources = ["*"]
    actions = [
      "sqs:ListQueues"
    ]
  }
  statement {
    sid = "SQSAccess"
    effect = "Allow"
    resources = ["arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:logging-*"]
    actions = [
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "kms:Decrypt"
    ]
  }
}

resource "aws_iam_policy" "ec2-splunkforwarder-role-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name        = "ec2-splunkforwarder-role-policy"
  description = "Policy for Splunk Forwarder to read from S3 logging buckets"
  policy = "${data.aws_iam_policy_document.ec2-splunkforwarder-role-policy-doc.json}"
}

resource "aws_iam_role" "ec2-splunkforwarder-role" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "ec2-splunkforwarder-role"
  description = "Default instance role to allow CloudWatch logs access."
  assume_role_policy = "${data.aws_iam_policy_document.ec2-assume-role-policy.json}"
  tags = "${merge(local.default_tags, map(
    "Name", "ec2-splunkforwarder-role"
  ))}"
}

resource "aws_iam_role_policy_attachment" "ec2-splunkforwarder-role-policy-attach-managed" {
  count = "${local.region == "eu-west-2" ? length(local.aws_managed_policy_for_ec2-splunkforwarder-role) : 0}"
  role       = "${aws_iam_role.ec2-splunkforwarder-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/${element(local.aws_managed_policy_for_ec2-splunkforwarder-role, count.index)}"
}

resource "aws_iam_role_policy_attachment" "ec2-splunkforwarder-role-policy-attach-inline" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.ec2-splunkforwarder-role.name}"
  policy_arn = "${aws_iam_policy.ec2-splunkforwarder-role-policy.arn}"
}

resource "aws_iam_instance_profile" "ec2-splunkforwarder-instance-profile" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "ec2-splunkforwarder-instance-profile"
  role = "${aws_iam_role.ec2-splunkforwarder-role.name}"
}

