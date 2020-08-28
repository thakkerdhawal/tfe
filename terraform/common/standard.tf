#
# Consul Backend
#
terraform {
  backend "consul" {
    address = "ecomm.fm.rbsgrp.net:443"
    scheme  = "https"
    ca_file = "../../common/rbsca.cer"
    datacenter = "corenet-prd"
    lock = false 
    gzip = true
  }
}

#
# Providers
#

provider "aws" {
  version = "2.8"
  shared_credentials_file = "${var.credential_file}"
  region  = "${local.region}"
  profile = "${var.aws_profile}"
}

# us-east-1 provider needed for regional resources that are linked to global resources (eg firehose & cloudfront)
provider "aws" {
  alias   = "us-east-1"
  version = "2.8"
  shared_credentials_file = "${var.credential_file}"
  region  = "us-east-1"
  profile = "${var.aws_profile}"
}

# assume role for nwmss, used to update route table for peering and to add apigw instance to ss alb
provider "aws.ss-assume" {
  version = "2.8"
  shared_credentials_file = "${var.credential_file}"
  profile = "${var.aws_profile}"
  assume_role {
    role_arn = "arn:aws:iam::${local.account_number_shared-services[local.ss_environment]}:role/core_assume"
  }

  region = "${local.region}"
}

# used by ss and core to peer with CTO VPC.
provider "aws.ctovpcpeer" {
  version = "2.8"
  shared_credentials_file = "${var.credential_file}"
  profile = "${var.aws_profile}"
  assume_role {
    role_arn = "arn:aws:iam::254646363543:role/vpc_peering_role"
  }

  region = "eu-west-1"
}

provider "consul" {
  version = "1.0"
  address = "${var.consul_host}"
  scheme = "https"
  ca_file = "${var.consul_ca}"
  datacenter = "${var.consul_dc}"
}

provider "null" {
  version = "1.0"
}

provider template {
  version = "1.0"
}

provider tls {
  version = "1.1"
}

provider local {
  version = "1.1"
}

provider random {
  version = "2.0"
}

provider external {
  version = "1.0"
}

provider archive {
  version = "1.1"
}

#
# Common Consul Variables
#
data "consul_keys" "standard" {
  key {
    name = "bu"
    path = "${local.consul_key_inputprefix}/common/bu"
    default = ""
  }
  key {
    name = "owner"
    path = "${local.consul_key_inputprefix}/common/owner"
    default = ""
  }
  key {
    name = "costcenter"
    path = "${local.consul_key_inputprefix}/common/costcenter"
    default = ""
  }
}

#
# Variables
#

## Static variables
locals  {
  # Default tags for most AWS resources
  default_tags = {
    "Terraform" = "Yes"
    "Environment" = "${local.environment}"
    "Component" = "${local.component}"
    "Workspace" = "${terraform.workspace}"
    "Owner" = "DES"
    "Cost Center" = "${data.consul_keys.standard.var.costcenter}"
    "Business Unit" = "DES"
  }

  ## Prefix for new layout
  consul_key_inputprefix = "application/nwm/${local.environment}/variables/${local.account}"
  consul_key_outputprefix = "application/nwm/${local.environment}/terraform/${local.account}/outputs/${local.component}/${local.region}"

  ## workspace naming convention: <env>_<acc>_<components>_<region>
  environment = "${element(split("_",terraform.workspace),0)}"
  account = "${element(split("_",terraform.workspace),1)}"
  component = "${element(split("_",terraform.workspace),2)}"
  region = "${element(split("_",terraform.workspace),3)}"
  ss_environment = "${local.environment == "nonprod" ? "prod":local.environment}"

  artifactory_prefix = "https://artifactory-1.dts.fm.rbsgrp.net/artifactory/eComm-public-releases-local"

  account_alias_shared-services = {
    lab = "nwmsstest"
    cicd = "nwmsstest"
    prod = "nwmssprod"
  }

  account_alias_core = {
    lab = "nwmtest"
    cicd = "nwmtest"
    nonprod = "nwmnonprod"
    prod = "nwmprod"
  }
  
 account_number_shared-services = {
    lab  = "897059257821"
    cicd = "897059257821"
    prod = "042627662550"
  }

  account_number_core = {
    lab     = "724329805838"
    cicd    = "724329805838"
    nonprod = "106756092552"
    prod    = "128363688939"
  }
}

## Required input variables

variable "aws_profile" {
   description = "ss aws profile"
   default = ""
}

variable "credential_file" {
   description = "path to cred file "
   default = ""
}

# Input variables with default value
variable "consul_host" {
  description = "hostname:port of the Consul server"
  default = "ecomm.fm.rbsgrp.net:443"
}
variable "consul_dc" {
  description = "Datacenter of the Consul cluster"
  default = "corenet-prd"
}
variable "consul_ca" {
  description = "Local file containing the Root CA cert of the Server certificate used by Consul"
  default = "../../common/rbsca.cer"
}

#
# Default Consul Output
#
data "external" "git" {
  program = ["bash", "../../common/get_git_info.sh"]
}
resource "consul_key_prefix" "default_output" {
  path_prefix = "${local.consul_key_outputprefix}."
  subkeys {
    "git_info" = "${jsonencode(data.external.git.result)}"
  }
}
