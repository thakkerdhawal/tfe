resource "aws_iam_account_password_policy" "password_policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  minimum_password_length        = 16
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 30
  password_reuse_prevention      = 12
}

