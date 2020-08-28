
data "aws_s3_bucket" "logs" {
  bucket = "logging-${local.account_alias_shared-services[local.environment]}-vpcflow-${local.region}"
}
