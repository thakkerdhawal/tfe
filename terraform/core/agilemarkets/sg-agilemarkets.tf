###### 
# External ALB for agilemarkets.com
#
resource "aws_security_group" "agilemarkets-alb-sg" {
  name        = "${local.environment}-agilemarkets-sg"
  description = "SG for external facing load balancer of the ${local.environment} agilemarkets.com"
  vpc_id      = "${data.aws_vpc.core.id}"
  tags = "${merge(local.default_tags, local.agilemarkets_tags,  map(
    "Name", "${local.environment}-agilemarkets-sg"
  ))}"
}

resource "aws_security_group_rule" "agilemarkets-ingress-https" {
  security_group_id = "${aws_security_group.agilemarkets-alb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from RBS proxy"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.v.var.public_alb_allowed_cidrs)}"]
}

resource "aws_security_group_rule" "agilemarkets-ingress-http" {
  security_group_id = "${aws_security_group.agilemarkets-alb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from RBS proxy"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.v.var.public_alb_allowed_cidrs)}"]
}

resource "aws_security_group_rule" "agilemarkets-lb-egress-apigw-https" {
  security_group_id = "${aws_security_group.agilemarkets-alb-sg.id}"
  type              = "egress"
  description       = "Destination is CA API Gateway traffic and monitor port"
  from_port         = 9443
  to_port           = 9444
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.apigw-sg.id}"
}

resource "aws_security_group_rule" "agilemarkets-lb-egress-apache-https" {
  security_group_id = "${aws_security_group.agilemarkets-alb-sg.id}"
  type              = "egress"
  description       = "Destination from ALB to Apache"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.apache-sg.id}"
}

#
# Internal ALB for agilemarkets topicenabler
# 
resource "aws_security_group" "agilemarkets-internal-alb-sg" {
  name        = "${local.environment}-agilemarkets-internal-sg"
  description = "SG for internal facing load balancer of the ${local.environment} agilemarkets.com for TopicEnabler"
  vpc_id      = "${data.aws_vpc.core.id}"
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-agilemarkets-internal-sg"
  ))}"
}

resource "aws_security_group_rule" "agilemarkets-internal-ingress-https" {
  security_group_id = "${aws_security_group.agilemarkets-internal-alb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from Stream Servers"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.stream-sg.id}"
}

resource "aws_security_group_rule" "agilemarkets-internal-egress-apigw-https" {
  security_group_id = "${aws_security_group.agilemarkets-internal-alb-sg.id}"
  type              = "egress"
  description       = "Destination is CA API Gateway traffic and monitor port"
  from_port         = 9443
  to_port           = 9444
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.apigw-sg.id}"
}

