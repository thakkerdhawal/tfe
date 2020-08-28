data "aws_iam_policy_document" "packer-apigw-policy" {
  count = "${local.region == "eu-west-2" && local.environment == "lab" ? 1 : 0}"
  statement {
    effect = "Allow"
    resources = ["arn:aws:s3:::nwm-ca-apigw-patches/*"]
    actions = [
          "s3:GetObject"
    ]
  }
}

resource "aws_iam_role" "packer-apigw-role" {
  count = "${local.region == "eu-west-2" && local.environment == "lab" ? 1 : 0}"
  name = "packer-apigw-role"
  description = "Instance role to allow Packer build instance to access API Gateway S3 buckets."
  assume_role_policy = "${data.aws_iam_policy_document.ec2-assume-role-policy.json}"
  tags = "${merge(local.default_tags, map(
    "Name", "packer-apigw-role"
  ))}"
}

resource "aws_iam_role_policy" "packer-apigw-role-policy" {
  count = "${local.region == "eu-west-2" && local.environment == "lab" ? 1 : 0}"
  name = "packer-apigw-role-policy"
  role = "${aws_iam_role.packer-apigw-role.name}"
  policy = "${data.aws_iam_policy_document.packer-apigw-policy.json}"
}

resource "aws_iam_instance_profile" "packer-apigw-instance-profile" {
  count = "${local.region == "eu-west-2" && local.environment == "lab" ? 1 : 0}"
  name = "packer-apigw-instance-profile"
  role = "${aws_iam_role.packer-apigw-role.name}"
}
