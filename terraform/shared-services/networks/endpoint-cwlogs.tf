data "aws_vpc_endpoint_service" "cwlogs" {
  service = "logs"
}

resource "aws_vpc_endpoint" "cloudwatch-logs-interface" {
  vpc_id            = "${module.vpcss.vpc_id}"
  service_name      = "${data.aws_vpc_endpoint_service.cwlogs.service_name}"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    "${aws_security_group.aws-vpc-endpoint-sg.id}",
  ]
  subnet_ids = ["${module.vpcss.intra_subnets}"]
  private_dns_enabled = true
}
