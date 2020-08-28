# Create a policy for densify
resource "aws_iam_policy" "svc_densify-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name        = "DES-DensifyMinimumReadAccess-Policy"
  description = "Policy for densify service account"
  policy = "${data.aws_iam_policy_document.svc_densify-policy-doc.json}"
}

resource "aws_iam_user" "svc_densify" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "svc_densify"
  tags = "${merge(local.default_tags, map(
    "Name", "svc_densify"
  ))}"
}

resource "aws_iam_user_policy_attachment" "svc_densify-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  user       = "${aws_iam_user.svc_densify.name}"
  policy_arn = "${aws_iam_policy.svc_densify-policy.arn}"
}

data "aws_iam_policy_document" "svc_densify-policy-doc" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    sid = "DensifyMinimumReadAccess"
    effect = "Allow"
    resources = ["*"]
    actions = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLaunchConfigurations",
        "cloudformation:DescribeStackResources",
        "cloudformation:ListStackResources",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "ec2:DescribeHosts",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:DescribeReservedInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeVolumes",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ecs:DescribeClusters",
        "ecs:DescribeContainerInstances",
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:ListClusters",
        "ecs:ListContainerInstances",
        "ecs:ListServices",
        "ecs:ListTaskDefinitions",
        "elasticache:DescribeCacheClusters",
        "elasticache:DescribeReplicationGroups",
        "elasticache:ListTagsForResource",
        "iam:ListAccountAliases",
        "iam:GetUser",
        "organizations:DescribeOrganization",
        "organizations:ListAccounts",
        "rds:DescribeDBInstances",
        "rds:DescribeReservedDBInstances",
        "rds:DescribeDBClusters",
        "rds:ListTagsForResource"
    ]
  }
}


