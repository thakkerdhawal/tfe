# Define a default assume role policy
data "aws_iam_policy_document" "assume-role-with-saml" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
      effect = "Allow"
      principals {
        type = "Federated"
        identifiers = ["${aws_iam_saml_provider.saml_provider.arn}"]
      }
      actions = ["sts:AssumeRoleWithSAML"]
      condition {
        test = "StringEquals" 
        variable = "SAML:aud"
        values = ["https://signin.aws.amazon.com/saml"]
      }
  }
}

# Create a custom policy, DES-PowerUsers-Policy
# TODO: config and events are added for CloudForms testing - remove?
data "aws_iam_policy_document" "des-powerusers-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement { 
    sid = "permittedServices"
    effect = "Allow"
    resources = ["*"]
    actions = [
                "acm:*",
                "autoscaling:*",
                "cloudfront:*",
                "cloudtrail:*",
                "cloudwatch:*",
                "config:*",
                "directconnect:*",
                "ec2:*",
                "events:*",
                "elasticloadbalancing:*",
                "firehose:*",
                "guardduty:*",
                "kms:*",
                "lambda:*",
                "logs:*",
                "rds:*",
                "route53:*",
                "route53domains:*",
                "s3:*",
                "sns:*",
                "shield:*",
                "support:*",
                "waf:*",
                "waf-regional:*",
                "iam:PassRole",
                "iam:GetRole",
                "iam:CreateServiceLinkedRole",
                "iam:ListAccountAliases",
                "sts:GetFederationToken",
                "sts:GetCallerIdentity"
    ]
  }
  statement { 
    sid = "RestrictRegions"
    actions = [
		"vpc:*",
                "ec2:*",
    ]
    resources = ["*"]
    effect = "Deny"
    condition = {
      test = "ForAnyValue:StringNotEqualsIfExists"
      variable = "aws:RequestedRegion"
      values = [
        "eu-west-1",
        "eu-west-2"
      ]
    }
  }

  statement { 
    sid = "VPCPeering"
    effect = "Allow"
    resources = [
         "arn:aws:iam::254646363543:role/vpc_peering_role",
         "arn:aws:iam::${local.account_number_shared-services[local.ss_environment]}:role/core_assume",
    ]
    actions = [
      "sts:AssumeRole"
    ]
  }
}

