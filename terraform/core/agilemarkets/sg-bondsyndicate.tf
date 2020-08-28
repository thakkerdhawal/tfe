# Update Apache SG to allow inbound traffic from BondySyndicate LB
resource "aws_security_group_rule" "apache-ingress-https-bondsyndicate" {
  security_group_id = "${aws_security_group.apache-sg.id}"
  type              = "ingress"
  description       = "Allow connection to Apche Instances from ALB for BondSyndicate"
  from_port = 8444
  to_port   = 8444
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.bondsyndicate-alb-sg.id}"
}

######
# External ALB for bondsyndicate
#
resource "aws_security_group" "bondsyndicate-alb-sg" {
  name        = "${local.environment}-bondsyndicate-sg"
  description = "SG for external facing load balancer of the ${local.environment} bondsyndicate"
  vpc_id      = "${data.aws_vpc.core.id}"
  tags = "${merge(local.default_tags, local.bondsyndicate_tags, map(
    "Name", "${local.environment}-bondsyndicate-alb-sg"
  ))}"
}

resource "aws_security_group_rule" "bondsyndicate-ingress-https" {
  security_group_id = "${aws_security_group.bondsyndicate-alb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from RBS proxy"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.bondsyndicate.var.public_alb_allowed_cidrs)}"]
}

resource "aws_security_group_rule" "bondsyndicate-ingress-http" {
  security_group_id = "${aws_security_group.bondsyndicate-alb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from RBS proxy"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.bondsyndicate.var.public_alb_allowed_cidrs)}"]
}

resource "aws_security_group_rule" "bondsyndicate-lb-egress-apache-https" {
  security_group_id = "${aws_security_group.bondsyndicate-alb-sg.id}"
  type              = "egress"
  description       = "Destination from ALB to Apache"
  from_port         = 8444
  to_port           = 8444
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.apache-sg.id}"
}





