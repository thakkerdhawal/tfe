resource "aws_security_group" "blackduck-hub-sg" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  name        = "Black Duck Hub"
  description = "Access to the Blackduck Hub"
  vpc_id      = "${data.consul_keys.import.var.vpc_id}"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck-hub-sg"
  ))}"
}

resource "aws_security_group_rule" "blackduck-hub-ingress-https" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  security_group_id = "${aws_security_group.blackduck-hub-sg.id}"
  type              = "ingress"
  description       = "Allow HTTPS access from the alb"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.blackduck-hub-lb-sg.id}"
}

resource "aws_security_group_rule" "blackduck-hub-egress-rds" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  security_group_id = "${aws_security_group.blackduck-hub-sg.id}"
  type              = "egress"
  description       = "Allow access to the RDS"
  from_port = "5432"
  to_port   = "5432"
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.blackduck-rds-sg.id}"
}

resource "aws_security_group_rule" "blackduck-hub-egress-https" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  security_group_id = "${aws_security_group.blackduck-hub-sg.id}"
  type              = "egress"
  description       = "Allow HTTPS access from blackduck hub out to contact Blackduck HQ"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
}

# External LB
resource "aws_security_group" "blackduck-hub-lb-sg" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  name        = "blackduck-hub-lb-sg"
  description = "SG for external facing load balancer of the Blackduck Hub"
  vpc_id      = "${data.consul_keys.import.var.vpc_id}"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck-hub-lb-sg"
  ))}"
}

resource "aws_security_group_rule" "blackduck-hub-lb-ingress1" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  security_group_id = "${aws_security_group.blackduck-hub-lb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from RBS proxy"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.blackduck.var.blackduck_public_allowed_cidrs)}"]
}

resource "aws_security_group_rule" "blackduck-hub-lb-egress1" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  security_group_id = "${aws_security_group.blackduck-hub-lb-sg.id}"
  type              = "egress"
  description       = "Only destination is blackduck hub node"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.blackduck-hub-sg.id}"
}

# Internal LB
resource "aws_security_group" "blackduck-int-lb-sg" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  name        = "blackduck-int-lb-sg"
  description = "SG for intenral facing load balancer of the Blackduck Hub"
  vpc_id      = "${data.consul_keys.import.var.vpc_id}"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck-int-lb-sg"
  ))}"
}

resource "aws_security_group_rule" "blackduck-int-lb-ingress1" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  security_group_id = "${aws_security_group.blackduck-int-lb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from intenral RBS proxy"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.blackduck.var.rbs_lanproxy_cidrs)}"]
}

resource "aws_security_group_rule" "blackduck-int-lb-egress1" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  security_group_id = "${aws_security_group.blackduck-int-lb-sg.id}"
  type              = "egress"
  description       = "Only destination is blackduck hub node"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.blackduck-hub-sg.id}"
}

# RDS 
resource "aws_security_group" "blackduck-rds-sg" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  name        = "Black Duck Database"
  description = "Access to the Blackduck Database"
  vpc_id      = "${data.consul_keys.import.var.vpc_id}"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck-rds-sg"
  ))}"
}

resource "aws_security_group_rule" "blackduck-rds-ingress" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  security_group_id = "${aws_security_group.blackduck-rds-sg.id}"
  type              = "ingress"
  description       = "Allow access from the blackduck instance"
  from_port = "5432"
  to_port   = "5432"
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.blackduck-hub-sg.id}"
}

