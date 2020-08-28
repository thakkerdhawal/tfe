
data "aws_iam_role" "aws_config_role" {
  name = "aws_config_role"
}

data "aws_kms_alias" "ebs_volume" {
  name = "alias/aws/ebs"
}

data "aws_iam_account_alias" "current" {}

