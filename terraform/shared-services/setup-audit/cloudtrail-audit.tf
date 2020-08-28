data "aws_iam_account_alias" "current" {}

data "aws_iam_role" "ct-cw-role" {
  name = "cloudtrail-cloudwatchlogs-role"
}

resource "aws_cloudwatch_log_group" "ct-audit-lg" {
  count = "${ local.environment == "cicd" ? 0:1 }"
  name = "cloudtrail-audit-loggroup"
}
  
resource "aws_cloudtrail" "ct-audit" {
  count = "${ local.environment == "cicd" ? 0:1 }"
  name                          = "cloudtrail-audit-${local.account}-${local.region}"
  s3_bucket_name                = "logging-${data.aws_iam_account_alias.current.account_alias}-cloudtrail-${local.region}"
  is_multi_region_trail 	= true
  enable_log_file_validation	= true
  cloud_watch_logs_role_arn	= "${data.aws_iam_role.ct-cw-role.arn}"
  cloud_watch_logs_group_arn	= "${aws_cloudwatch_log_group.ct-audit-lg.arn}"
}
