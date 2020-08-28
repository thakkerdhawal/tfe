# Create queue
module "logging-queue-cloudfront" {
  global = true
  source = "./sqs-queue-for-logging"
  name = "cloudfront"
  default_tags = "${local.default_tags}"
  logging-dead-letter-queue-arn = "${aws_sqs_queue.logging-dead-letter-queue.arn}"
}

# Create buckets for Shared-Services account
module "logging-buckets-cloudfront-ss" {
  enabled = "${local.region == "eu-west-2" ? true : false}"
  global = true
  source = "./s3-bucket-for-logging"
  name = "cloudfront"
  account_alias = "${local.account_alias_shared-services[local.environment]}" 
  default_tags = "${local.default_tags}"
  s3-bucket-policy-doc = "${data.aws_iam_policy_document.s3-cloudfront-policy-doc-ss.json}"
  logging-sqs-queue-arn = "${module.logging-queue-cloudfront.sqs_queue_arn}"
}

# Create buckets for Core account
module "logging-buckets-cloudfront-core" {
  enabled = "${local.region == "eu-west-2" ? true : false}"
  global = true
  source = "./s3-bucket-for-logging"
  name = "cloudfront"
  account_alias = "${local.account_alias_core[local.environment]}" 
  default_tags = "${local.default_tags}"
  s3-bucket-policy-doc = "${data.aws_iam_policy_document.s3-cloudfront-policy-doc-core.json}"
  logging-sqs-queue-arn = "${module.logging-queue-cloudfront.sqs_queue_arn}"
}

# Create buckets for nonprod Core account
module "logging-buckets-cloudfront-core-nonprod" {
  enabled = "${local.region == "eu-west-2" && local.environment  == "prod" ? true : false}"
  global = true
  source = "./s3-bucket-for-logging"
  name = "cloudfront"
  account_alias = "${local.account_alias_core["nonprod"]}" 
  default_tags = "${local.default_tags}"
  s3-bucket-policy-doc = "${data.aws_iam_policy_document.s3-cloudfront-policy-doc-core-nonprod.json}"
  logging-sqs-queue-arn = "${module.logging-queue-cloudfront.sqs_queue_arn}"
}

