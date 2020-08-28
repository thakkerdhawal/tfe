# Liberator EC2 Instance Security Group
resource "aws_security_group" "stream-sg" {
  description       = "Security Group for Caplin Liberator EC2 instances"
  name        = "${local.account}-${local.environment}-stream-sg"
  vpc_id      = "${data.aws_vpc.core.id}"
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-stream-sg"
  ))}"
}

resource "aws_security_group_rule" "stream-ingress-traffic-https-agilemarkets" {
  security_group_id = "${aws_security_group.stream-sg.id}"
  type              = "ingress"
  description       = "Allow HTTPS access from the alb for Agilemarkets"
  from_port = "4447"
  to_port   = "4447"
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.stream-alb-sg.id}"
}

resource "aws_security_group_rule" "stream-ingress-traffic-mgmt-ss-https-agilemarkets" {
  security_group_id = "${aws_security_group.stream-sg.id}"
  type              = "ingress"
  description       = "Allow HTTPS access to mgmt ALB from Shared Services"
  from_port = "4447"
  to_port   = "4447"
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.import.var.intra_subnets_cidr_blocks)}"]
}

resource "aws_security_group_rule" "stream-ingress-data-sources-agilemarkets" {
  security_group_id = "${aws_security_group.stream-sg.id}"
  type              = "ingress"
  description       = "Allow Agilemarkets data source access"
  from_port = "25002"
  to_port   = "25002"
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.stream.var.stream_data_source_cidrs)}"]
}

resource "aws_security_group_rule" "stream-egress-traffic-https-agilemarkets-internal-alb" {
  security_group_id = "${aws_security_group.stream-sg.id}"
  type              = "egress"
  description       = "Allow HTTPS access from the Liberator to the internal Agilemarkets ALB for TopicEnabler"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.agilemarkets-internal-alb-sg.id}"
}

resource "aws_security_group_rule" "stream-egress-traffic-https-s3" {
  security_group_id = "${aws_security_group.stream-sg.id}"
  type              = "egress"
  description       = "Allow HTTPS access from the Liberator to S3 for Binary log shipping"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
  prefix_list_ids = ["${data.aws_vpc_endpoint.s3.prefix_list_id}"]
}

#
# Liberator External ALB Security Group
#
resource "aws_security_group" "stream-alb-sg" {
  name = "${local.environment}-stream-alb-sg"
  description = "SG for external facing load balancer of Caplin Liberator"
  vpc_id = "${data.aws_vpc.core.id}"
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-stream-alb-sg"
  ))}"
}

resource "aws_security_group_rule" "stream-alb-ingress-https" {
  security_group_id = "${aws_security_group.stream-alb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from RBS proxy and trusted test IPs"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.v.var.public_alb_allowed_cidrs)}"]
}

resource "aws_security_group_rule" "stream-alb-egress-https-agilemarkets" {
  security_group_id = "${aws_security_group.stream-alb-sg.id}"
  type              = "egress"
  description       = "Only destination is the Liberator instances"
  from_port         = "4447"
  to_port           = "4447"
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.stream-sg.id}"
}

