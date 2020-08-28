data "aws_vpc_endpoint_service" "cw" {
  service = "monitoring"
}

resource "aws_vpc_endpoint" "cloudwatch-metrics-interface" {
  vpc_id            = "${module.vpcnwm.vpc_id}"
  service_name      = "${data.aws_vpc_endpoint_service.cw.service_name}"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    "${aws_security_group.aws-vpc-endpoint-sg.id}",
  ]
  subnet_ids = ["${module.vpcnwm.intra_subnets}"]
  private_dns_enabled = true
}

