data "aws_caller_identity" "current" {}

locals {
  sns_subscribed_accounts = "${local.environment == "prod" ? "${local.account_number_core[local.environment]},${local.account_number_core["nonprod"]}":local.account_number_core[local.environment]}"
}

data "aws_iam_policy_document" "netcool-sns-policy" {
 statement {
    sid = "netcoolsnspolicy"
    principals {
      identifiers = ["*"]
      type = "AWS"
    }
    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:Receive",
      "SNS:AddPermission",
      "SNS:Subscribe"
    ]
   resources = [
      "arn:aws:sns:${local.region}:${data.aws_caller_identity.current.account_id}:${local.environment}-netcool-sns-topic"
    ]
    condition {
      test = "StringEquals"
      values = ["${local.account_number_shared-services[local.environment]}"]
      variable = "AWS:SourceOwner"
    }
  }

 statement {
   sid = "inbound"
   principals {
      identifiers = ["*"]
      type = "AWS"
   }
   actions = [
     "SNS:Publish"
   ] 
   resources = [
      "arn:aws:sns:${local.region}:${data.aws_caller_identity.current.account_id}:${local.environment}-netcool-sns-topic"
    ]
    condition {
      test = "StringEquals"
      values = ["${split(",", local.sns_subscribed_accounts)}"]
      variable = "AWS:SourceOwner"
    }
  }
}
