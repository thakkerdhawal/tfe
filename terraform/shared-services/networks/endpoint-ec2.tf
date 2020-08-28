data "aws_vpc_endpoint_service" "ec2" {
  service = "ec2"
}

resource "aws_vpc_endpoint" "ec2-interface" {
  vpc_id            = "${module.vpcss.vpc_id}"
  service_name      = "${data.aws_vpc_endpoint_service.ec2.service_name}"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    "${aws_security_group.aws-vpc-endpoint-sg.id}",
  ]
  subnet_ids = ["${module.vpcss.intra_subnets}"]
  private_dns_enabled = true
}

