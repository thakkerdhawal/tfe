provider "aws.replica" {
  version = "2.8"
  shared_credentials_file = "${var.credential_file}"
  region  = "${local.replica_region}"
  profile = "${var.aws_profile}"
}
