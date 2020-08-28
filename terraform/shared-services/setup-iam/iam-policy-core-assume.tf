
locals {
  core_accounts = "${local.environment == "prod" ? "${local.account_number_core[local.environment]},${local.account_number_core["nonprod"]}":"${local.account_number_core[local.environment]}"}"
}

data "aws_iam_policy_document" "core_assume" {
  statement {
    actions = [
      "ec2:CreateVpcPeeringConnection",
      "ec2:DeleteVpcPeeringConnection",
    ]

    resources = [
      "arn:aws:ec2:eu-west-1:${data.aws_caller_identity.current.account_id}:vpc/*",
      "arn:aws:ec2:eu-west-2:${data.aws_caller_identity.current.account_id}:vpc/*",
    ]
  }

  statement {
    actions = [
      "ec2:CreateVpcPeeringConnection",
      "ec2:DeleteVpcPeeringConnection",
    ]

    resources = [
      "arn:aws:ec2:eu-west-1:${data.aws_caller_identity.current.account_id}:vpc-peering-connection/*",
      "arn:aws:ec2:eu-west-2:${data.aws_caller_identity.current.account_id}:vpc-peering-connection/*",
    ]

    condition = {
      test     = "ArnEquals"
      variable = "ec2:AccepterVpc"

      values = [
        "${formatlist("%s%s%s","arn:aws:ec2:eu-west-1:", data.template_file.core-accounts.*.rendered, ":vpc/*")}",
        "${formatlist("%s%s%s","arn:aws:ec2:eu-west-2:",data.template_file.core-accounts.*.rendered, ":vpc/*")}",
      ]
    }
  }

  statement {

    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeVpcPeeringConnections",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
        "arn:aws:lambda:eu-west-1:${local.account_number_shared-services[local.environment]}:function:*-create_route_table_entry",
        "arn:aws:lambda:eu-west-2:${local.account_number_shared-services[local.environment]}:function:*-create_route_table_entry",
        "arn:aws:lambda:eu-west-1:${local.account_number_shared-services[local.environment]}:function:*-add-instance-to-mgmt-alb",
        "arn:aws:lambda:eu-west-2:${local.account_number_shared-services[local.environment]}:function:*-add-instance-to-mgmt-alb",
    ]
  }
}
