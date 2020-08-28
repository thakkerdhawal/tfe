# SG - netcool lambdas.
resource "aws_security_group" "netcool-lambda-sg" {
  name        = "${local.environment}-netcool-lambda-sg"
  description = "SG for netcool lambda"
  vpc_id      = "${module.vpcss.vpc_id}"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-netcool-lambda-sg"
  ))}"
}

resource "aws_security_group_rule" "netcool-egress-https" {
  security_group_id = "${aws_security_group.netcool-lambda-sg.id}"
  type              = "egress"
  description       = "Destination is Campus VIP for netcool lambda"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${data.consul_keys.netcool.var.netcool_ip}"]
}
