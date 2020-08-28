# Only create this user in LAB account
resource "aws_iam_user" "svc_teamcity" {
  count = "${local.region == "eu-west-2" && local.environment == "lab" ? 1 : 0}"
  name = "svc_teamcity"
  tags = "${merge(local.default_tags, map(
    "Name", "svc_teamcity"
  ))}"
}

resource "aws_iam_user_policy_attachment" "svc_teamcity-policy" {
  count = "${local.region == "eu-west-2" && local.environment == "lab" ? 1 : 0}"
  user       = "${aws_iam_user.svc_teamcity.name}"
  policy_arn = "${aws_iam_policy.des-powerusers-policy.arn}"
}
