######
# External ALB for currencypay.natwestmarkets.com
#
resource "aws_security_group" "currencypay-alb-sg" {
  name        = "${local.environment}-currencypay-sg"
  description = "SG for external facing load balancer of the ${local.environment} currencypay.natwestmarkets.com"
  vpc_id      = "${data.aws_vpc.core.id}"
  tags = "${merge(local.default_tags, local.currencypay_tags, map(
    "Name", "${local.environment}-currencypay-sg"
  ))}"
}

resource "aws_security_group_rule" "currencypay-ingress-https" {
  security_group_id = "${aws_security_group.currencypay-alb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from RBS proxy"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.v.var.public_alb_allowed_cidrs)}"]
}

resource "aws_security_group_rule" "currencypay-ingress-http" {
  security_group_id = "${aws_security_group.currencypay-alb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from RBS proxy"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.v.var.public_alb_allowed_cidrs)}"]
}

resource "aws_security_group_rule" "currencypay-lb-egress-apigw-https" {
  security_group_id = "${aws_security_group.currencypay-alb-sg.id}"
  type              = "egress"
  description       = "Destination is CA API Gateway traffic and monitor port"
  from_port         = 9443
  to_port           = 9444
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.apigw-sg.id}"
}
