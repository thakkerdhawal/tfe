locals {
  replica_region = "${local.region == "eu-west-1" ? "eu-west-2" : "eu-west-1"}"
  aws_elb_account_number = {
    eu-west-1  = "156460612806"
    eu-west-2 = "652711504416"
  }
}

