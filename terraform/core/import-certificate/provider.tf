provider "aws" {
  version = "2.8"
  shared_credentials_file = "${var.credential_file}"
  region  = "${local.region}"
  profile = "${var.aws_profile}"
}

