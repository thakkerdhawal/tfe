resource "aws_iam_role" "aws-shield-drt-access" {
  count              = "${local.region == "eu-west-2" ? 1 : 0}"
  name               = "aws-shield-drt-access"
  description        = "Role for DDoS response team to review AWS resources in your account and to mitigate DDoS attacks against your infrastructure by creating WAF rules and AWS Shield protections."
  assume_role_policy = "${data.aws_iam_policy_document.drt-assume-role-policy.json}"
  tags = "${merge(local.default_tags, map(
    "Name", "aws-shield-drt-access"
  ))}"
}

resource "aws_iam_role_policy_attachment" "aws-shield-drt-access-role-policy-attach" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.aws-shield-drt-access.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSShieldDRTAccessPolicy"
}
