locals {
  aws_managed_policy_for_svc_geneos = ["CloudWatchReadOnlyAccess","AmazonEC2ReadOnlyAccess"]
}

# Create a policy for geneos
resource "aws_iam_user" "svc_geneos" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "svc_geneos"
  tags = "${merge(local.default_tags, map(
    "Name", "svc_geneos"
  ))}"
}

resource "aws_iam_user_policy_attachment" "svc_geneos-policy" {
  count = "${local.region == "eu-west-2" ? length(local.aws_managed_policy_for_svc_geneos) : 0}"
  user       = "${aws_iam_user.svc_geneos.name}"
  policy_arn = "arn:aws:iam::aws:policy/${element(local.aws_managed_policy_for_svc_geneos, count.index)}"
}

