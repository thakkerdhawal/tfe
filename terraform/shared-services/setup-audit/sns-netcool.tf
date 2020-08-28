resource "aws_sns_topic" "netcool-sns" {
  name   = "${local.environment}-netcool-sns-topic"
  policy = "${data.aws_iam_policy_document.netcool-sns-policy.json}"
}
