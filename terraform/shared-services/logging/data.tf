data "aws_ami" "des-rhel7-ami" {
  # We do not allow multiple AMI with same version
  most_recent      = false
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "tag:Name"
    values = ["nwm-rhel7-ami"]
  }
  filter {
    name   = "tag:Version"
    values = ["${data.consul_keys.v.var.des_rhel7_ami_version_filter}"]
  }
  owners     = ["self"]
}

data "aws_acm_certificate" "splunk-cert" {
  count = "${ local.environment == "lab" || local.environment == "cicd" ? 1:0 }"
  domain = "${data.consul_keys.v.var.logging_cert_domain}"
  statuses = ["ISSUED"]
  most_recent = true
}

data "aws_instances" "bastion-host" {
  instance_tags {
    Name = "${local.environment}-bastionnode-*"
  }
  instance_state_names = ["running"]
}


data "aws_vpc" "ss" {
  tags {
    Name = "${local.environment}-vpc"
  }
}

data "aws_subnet_ids" "intra_subnets" {
  vpc_id = "${data.aws_vpc.ss.id}"
  tags = {
    Name = "${local.environment}-vpc-intra-${local.region}"
  }
}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = "${data.aws_vpc.ss.id}"
  tags = {
    Name = "${local.environment}-vpc-private-${local.region}"
  }
}

data "aws_security_group" "all-hosts-sg" {
  name = "${local.environment}-all-hosts-sg"
  vpc_id = "${data.aws_vpc.ss.id}"
}

