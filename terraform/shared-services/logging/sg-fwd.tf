locals { splunk_indexer_ldn = ["11.160.94.210/32","11.160.94.211/32","11.191.99.103/32","11.161.40.144/32","11.191.39.123/32","11.191.39.124/32"] }
# SG - logging instances
resource "aws_security_group" "splunk-fwd-sg" {
  name        = "${local.environment}-splunk-fwd-sg"
  description = "SG for Splunk Forwarder instances"
  vpc_id      = "${data.aws_vpc.ss.id}"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-splunk-fwd-sg"
  ))}"
}

resource "aws_security_group_rule" "splunk-fwd-instance-ingress-https" {
  count = "${ local.environment == "lab" ? 1:0 }"
  security_group_id = "${aws_security_group.splunk-fwd-sg.id}"
  type              = "ingress"
  description       = "Allow connection to Splunk WebUI from internal facing ALB"
  from_port = 8443
  to_port   = 8443
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.splunk-fwd-int-lb-sg.id}"
}

resource "aws_security_group_rule" "splunk-fwd-instance-egress-tcp-lab" {
  count = "${ local.environment == "lab" ? 1:0 }"
  security_group_id = "${aws_security_group.splunk-fwd-sg.id}"
  type              = "egress"
  description       = "Allow outbound connection to dummy splunk indexers"
  from_port         = 9999
  to_port           = 9999
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.splunk-web-sg.id}"
}

resource "aws_security_group_rule" "splunk-fwd-instance-egress-tcp-prd" {
  count = "${ local.environment == "prod" ? 1:0 }"
  security_group_id = "${aws_security_group.splunk-fwd-sg.id}"
  type              = "egress"
  description       = "Allow outbound connection to RBS splunk indexers"
  from_port         = 9999
  to_port           = 9999
  protocol          = "tcp"
  cidr_blocks       = "${local.splunk_indexer_ldn}"
}

# Access AWS endpoints
resource "aws_security_group_rule" "splunk-fwd-instance-egress-https" {
  security_group_id = "${aws_security_group.splunk-fwd-sg.id}"
  type              = "egress"
  description       = "Allow outbound connection HTTPS Endpoints"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}


# SG - Internal Facing LB
resource "aws_security_group" "splunk-fwd-int-lb-sg" {
  count = "${ local.environment == "lab" ? 1:0 }"
  name        = "${local.environment}-splunk-fwd-int-lb-sg"
  description = "SG for Splunk Internal facing ALB"
  vpc_id      = "${data.aws_vpc.ss.id}"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-splunk-fwd-int-lb-sg"
  ))}"
}

resource "aws_security_group_rule" "splunk-fwd-int-lb-ingress-https" {
  count = "${ local.environment == "lab" ? 1:0 }"
  security_group_id = "${aws_security_group.splunk-fwd-int-lb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from internal RBS proxy"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.v.var.rbs_lanproxy_cidrs)}"]
}

resource "aws_security_group_rule" "splunk-fwd-int-lb-egress-https" {
  count = "${ local.environment == "lab" ? 1:0 }"
  security_group_id = "${aws_security_group.splunk-fwd-int-lb-sg.id}"
  type              = "egress"
  description       = "Only destination is splunk instances"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.splunk-fwd-sg.id}"
}
