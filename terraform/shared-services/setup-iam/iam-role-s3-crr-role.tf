data "aws_iam_policy_document"  "s3-crr-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    effect = "Allow"
    resources = [
        "arn:aws:s3:::logging-*",
        "arn:aws:s3:::logging-*/*"
    ]
    actions = [
        "s3:Get*",
        "s3:ListBucket"
    ]
  }

  statement {
    effect = "Allow"
    resources = [
          "arn:aws:s3:::logging-*-replica/*"
        ]
    actions = [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags",
        "s3:GetObjectVersionTagging"
    ]
  }

}


resource "aws_iam_role" "s3-crr-role" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "s3-crr-role"
  assume_role_policy = "${data.aws_iam_policy_document.s3-assume-role-policy.json}"
}


resource "aws_iam_role_policy"  "policy-attachement" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name      = "s3-crr-role-policy"
  role      =  "${aws_iam_role.s3-crr-role.name}"
  policy    = "${data.aws_iam_policy_document.s3-crr-policy.json}"
}


