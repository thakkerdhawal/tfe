data "aws_iam_policy_document" "s3-assume-role-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2-assume-role-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda-assume-role-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "drt-assume-role-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["drt.shield.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "aws-config-assume-role-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]

    }

  }
}

data "aws_iam_policy_document" "cloudwatchlogs-assume-role-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "firehose-assume-role-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudtrail-assume-role-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

data "template_file" "core-accounts" {
  template = "$${account}"
  count    = "${length(split(",",local.core_accounts))}"

  vars {
    account = "${element(split(",",local.core_accounts),count.index)}"
  }
}

data "aws_iam_policy_document" "core_assume-role-policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${formatlist("%s%s%s","arn:aws:iam::", data.template_file.core-accounts.*.rendered, ":root")}"]
    }
  }
}
