locals {
  aws_managed_policy_for_ec2-default-role = ["CloudWatchAgentServerPolicy"]
}
resource "aws_iam_role" "ec2-default-role" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "ec2-default-role"
  description = "Default instance role to allow CloudWatch logs access."
  assume_role_policy = "${data.aws_iam_policy_document.ec2-assume-role-policy.json}"
  tags = "${merge(local.default_tags, map(
    "Name", "ec2-default-role"
  ))}"
}

resource "aws_iam_role_policy_attachment" "ec2-default-role-policy" {
  count = "${local.region == "eu-west-2" ? length(local.aws_managed_policy_for_ec2-default-role) : 0}"
  role       = "${aws_iam_role.ec2-default-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/${element(local.aws_managed_policy_for_ec2-default-role, count.index)}"
}

resource "aws_iam_instance_profile" "ec2-default-instance-profile" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "ec2-default-instance-profile"
  role = "${aws_iam_role.ec2-default-role.name}"
}

