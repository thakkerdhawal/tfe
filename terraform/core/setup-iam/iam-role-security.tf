resource "aws_iam_role" "cto_security" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "security"
  description = "CTO Security Role"
  assume_role_policy = "${data.aws_iam_policy_document.cto_security_assume_role.json}"
}

data "aws_iam_policy_document" "cto_security_assume_role" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [
          "arn:aws:iam::398056940469:role/scoutsuite",
          "arn:aws:iam::418297296021:role/ADFS-Admin",
          "arn:aws:iam::418297296021:role/ADFS-StandardUser"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cto_security_ctoadfsrocustom" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.cto_security.name}"
  policy_arn = "${aws_iam_policy.ctoadfsrocustom.arn}"
}

resource "aws_iam_role_policy_attachment" "cto_security_readonlyaccess" {
  count      = "${local.region == "eu-west-2" ? 1 : 0}"
  role       = "${aws_iam_role.cto_security.name}"
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

