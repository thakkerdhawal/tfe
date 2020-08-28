data "aws_ami" "des-rhel7-ami" {
  # We should not have multiple AMI with same version
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

data "aws_ami" "des-apigw-ami" {
  # We should not have multiple AMI with same version
  most_recent      = false
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "tag:Name"
    values = ["des-ca-apigw-ami"]
  }
  filter {
    name   = "tag:Version"
    values = ["${data.consul_keys.apigw.var.des_apigw_ami_version_filter}"]
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

data "aws_route53_zone" "am_zone" {
  name         = "${local.environment}.cloud.agilemarkets.com."
}

data "aws_route53_zone" "nwm_zone" {
  name         = "${local.environment}.cloud.natwestmarkets.com."
}

data "aws_vpc_endpoint_service" "s3" {
  service = "s3"
}

data "aws_vpc_endpoint" "s3" {
  vpc_id       = "${data.aws_vpc.core.id}"
  service_name = "${data.aws_vpc_endpoint_service.s3.service_name}"
}


# add apigw instance to ss management alb 
data "aws_lambda_invocation" "add-instance-to-mgmt-alb" {
  provider      = "aws.ss-assume"
  count         = "${data.consul_keys.apigw.var.instance_count}"
  function_name = "${local.ss_environment}-add-instance-to-mgmt-alb"

  input = <<JSON
{
  "targetgroup_Name": "${local.environment}-apigw-mgmt-${count.index + 1}-tg", 
  "instance_IP": "${element(aws_instance.apigw.*.private_ip, count.index)}"
}
JSON

  depends_on = ["aws_instance.apigw"]
}
