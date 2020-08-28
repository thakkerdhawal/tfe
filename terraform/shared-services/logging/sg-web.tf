# SG - logging instances
resource "aws_security_group" "splunk-web-sg" {
  count = "${ local.environment == "lab" ? 1:0 }"
  name        = "${local.environment}-splunk-web-sg"
  description = "SG for Splunk Web instances"
  vpc_id      = "${data.aws_vpc.ss.id}"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-splunk-web-sg"
  ))}"
}

resource "aws_security_group_rule" "splunk-web-instance-ingress-https" {
  count = "${ local.environment == "lab" ? 1:0 }"
  security_group_id = "${aws_security_group.splunk-web-sg.id}"
  type              = "ingress"
  description       = "Allow connection to Splunk WebUI from internal facing ALB"
  from_port = 8443
  to_port   = 8443
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.splunk-web-int-lb-sg.id}"
}

resource "aws_security_group_rule" "splunk-web-instance-ingress-tcp" {
  count = "${ local.environment == "lab" ? 1:0 }"
  security_group_id = "${aws_security_group.splunk-web-sg.id}"
  type              = "ingress"
  description       = "Allow connection to Splunk data input from forwarders"
  from_port = 9999
  to_port   = 9999
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.splunk-fwd-sg.id}"
}

# SG - Internal Facing LB
resource "aws_security_group" "splunk-web-int-lb-sg" {
  count = "${ local.environment == "lab" ? 1:0 }"
  name        = "${local.environment}-splunk-web-int-lb-sg"
  description = "SG for Splunk Internal facing ALB"
  vpc_id      = "${data.aws_vpc.ss.id}"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-splunk-web-int-lb-sg"
  ))}"
}

resource "aws_security_group_rule" "splunk-web-int-lb-ingress-https" {
  count = "${ local.environment == "lab" ? 1:0 }"
  security_group_id = "${aws_security_group.splunk-web-int-lb-sg.id}"
  type              = "ingress"
  description       = "Allow connection from internal RBS proxy"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.v.var.rbs_lanproxy_cidrs)}"]
}

resource "aws_security_group_rule" "splunk-web-int-lb-egress-https" {
  count = "${ local.environment == "lab" ? 1:0 }"
  security_group_id = "${aws_security_group.splunk-web-int-lb-sg.id}"
  type              = "egress"
  description       = "Only destination is splunk instances"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.splunk-web-sg.id}"
}
