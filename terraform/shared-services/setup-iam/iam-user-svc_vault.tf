resource "aws_iam_user" "svc_vault" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "svc_vault"
  tags = "${merge(local.default_tags, map(
    "Name", "svc_vault"
  ))}"
}

resource "aws_iam_user_policy_attachment" "svc_vault-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  user       = "${aws_iam_user.svc_vault.name}"
  policy_arn = "${aws_iam_policy.des-powerusers-policy.arn}"
}
