# This file creates an iam group to add the various aws shared services and core accounts to the 
# group for access to the aws config
#
resource "aws_iam_role_policy_attachment" "managed_aws_config_policy" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.aws_config_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_iam_role" "aws_config_role" {
  count              = "${local.region == "eu-west-2" ? 1 : 0}"
  name               = "aws_config_role"
  description        = "aws config access"
  assume_role_policy = "${data.aws_iam_policy_document.aws-config-assume-role-policy.json}"
}
