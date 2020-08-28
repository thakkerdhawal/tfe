data "aws_route53_zone" "vlproxy_zone" {
  name         = "${local.environment}.cloud.natwestmarkets.com."
}

## Get public subnet of the AZ where vlproxy instance is provisioned (preferred to hardcoding ec2 instance AZ as a var)
data "aws_subnet" "vlproxyPublicSubnet" {
  availability_zone = "${aws_instance.vlproxy-ingress.availability_zone}"
    tags = {
    Name = "${local.environment}-vpc-public-${local.region}"
  }
}

data "aws_network_interface" "nlb-vlproxy-monitor-ips" {
  depends_on = ["aws_lb.nlb-vlproxy-monitor"]

  filter = {
    name   = "description"
    values = ["ELB net/${local.environment}-vlproxy-monitor-8080-nlb/*"]
  }
}

data "aws_network_interface" "nlb-vlproxy-ingress-ips" {
  depends_on = ["aws_lb.nlb-vlproxy-ingress"]

  filter = {
    name   = "description"
    values = ["ELB net/${local.environment}-vlproxy-ingress-nlb/*"]
  }

  filter = {
    name   = "subnet-id"
    values = ["${data.aws_subnet.vlproxyPublicSubnet.id}"]
  }
}

data "aws_eip" "vlproxy" {

  filter {
    name   = "tag:Name"
    values = ["${local.environment}-cleo"]
  }
}


data "aws_ami" "des-rhel7-ami" {
  most_recent      = true
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

data "aws_vpc" "core" {
  tags {
    Name = "${local.environment}-vpc"
  }
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = "${data.aws_vpc.core.id}"
 
  tags = {
    Name = "${local.environment}-vpc-public-${local.region}"
  }
}

data "aws_subnet_ids" "intra_subnets" {
  vpc_id = "${data.aws_vpc.core.id}"
  tags = {
    Name = "${local.environment}-vpc-intra-${local.region}"
  }
}

data "aws_security_group" "all-hosts-sg" {
  name = "${local.environment}-all-hosts-sg"
  vpc_id = "${data.aws_vpc.core.id}"
}
