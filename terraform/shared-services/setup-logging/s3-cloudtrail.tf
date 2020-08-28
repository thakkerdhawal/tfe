# Create queue
module "logging-queue-cloudtrail" {
  source = "./sqs-queue-for-logging"
  name = "cloudtrail"
  default_tags = "${local.default_tags}"
  logging-dead-letter-queue-arn = "${aws_sqs_queue.logging-dead-letter-queue.arn}"
}

# Create buckets for Shared-Services account
module "logging-buckets-cloudtrail-ss" {
  source = "./s3-bucket-for-logging"
  name = "cloudtrail"
  account_alias = "${local.account_alias_shared-services[local.environment]}" 
  default_tags = "${local.default_tags}"
  s3-bucket-policy-doc = "${data.aws_iam_policy_document.s3-cloudtrail-policy-doc-ss.json}"
  logging-sqs-queue-arn = "${module.logging-queue-cloudtrail.sqs_queue_arn}"
}

# Create buckets for Core account
module "logging-buckets-cloudtrail-core" {
  source = "./s3-bucket-for-logging"
  name = "cloudtrail"
  account_alias = "${local.account_alias_core[local.environment]}" 
  default_tags = "${local.default_tags}"
  s3-bucket-policy-doc = "${data.aws_iam_policy_document.s3-cloudtrail-policy-doc-core.json}"
  logging-sqs-queue-arn = "${module.logging-queue-cloudtrail.sqs_queue_arn}"
}

# Create buckets for nonprod Core account
module "logging-buckets-cloudtrail-core-nonprod" {
  enabled = "${local.environment  == "prod" ? true : false}"
  source = "./s3-bucket-for-logging"
  name = "cloudtrail"
  account_alias = "${local.account_alias_core["nonprod"]}" 
  default_tags = "${local.default_tags}"
  s3-bucket-policy-doc = "${data.aws_iam_policy_document.s3-cloudtrail-policy-doc-core-nonprod.json}"
  logging-sqs-queue-arn = "${module.logging-queue-cloudtrail.sqs_queue_arn}"
}

