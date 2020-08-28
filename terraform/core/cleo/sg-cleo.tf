###### Cleo VLProxy EC2 Instance Security Group ######
resource "aws_security_group" "vlproxy-ingress-sg" {
  description       = "Security Group for Cleo VLProxy EC2 instances"
  name        = "${local.environment}-vlproxy-ingress-sg"
  vpc_id      = "${data.aws_vpc.core.id}"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-vlproxy-ingress-sg"
  ))}"
}

## Cleo VLProxy Instance Ingress Rule for SFTP ##
resource "aws_security_group_rule" "vlproxy-ingress-traffic-sftp" {
  security_group_id = "${aws_security_group.vlproxy-ingress-sg.id}"
  type              = "ingress"
  description       = "Allow SFTP access on port 9022 from Outside World to VLProxy Instance"
  from_port = "9022"
  to_port   = "9022"
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.v.var.public_alb_allowed_cidrs)}"]
}

## Cleo VLProxy Instance Ingress Rule to allow Cleo Harmony Internal Instances to communicate##

resource "aws_security_group_rule" "vlproxy-ingress-traffic-harmony-8080" {
  security_group_id = "${aws_security_group.vlproxy-ingress-sg.id}"
  type              = "ingress"
  description       = "Allow Harmony Instances to talk to VLProxy Instance via tunnel"
  from_port = "8080"
  to_port   = "8080"
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.v.var.vlproxy_harmony_ips)}"]

}

## Cleo VLProxy SG rule to allow monitor port 8080 via LB

resource "aws_security_group_rule" "vlproxy-monitor-traffic-8080" {
  security_group_id = "${aws_security_group.vlproxy-ingress-sg.id}"
  type              = "ingress"
  description       = "Allow Monitor traffic on port 8080 from NLB"
  from_port = "8080"
  to_port   = "8080"
  protocol  = "tcp"
  cidr_blocks = ["${data.aws_network_interface.nlb-vlproxy-monitor-ips.private_ip}/32"]
}

## Cleo VLProxy Instance Ingress Rule to allow single Private IP of LB to talk to communicate with VLProxy ##

resource "aws_security_group_rule" "vlproxy-nlb-healthcheck-rule-9022" {
  security_group_id = "${aws_security_group.vlproxy-ingress-sg.id}"
  type              = "ingress"
  description       = "Allow NLB via its private interface to talk to VLProxy Instance to perform healthchecks on 9022"
  from_port = "9022"
  to_port   = "9022"
  protocol  = "tcp"
  cidr_blocks = ["${data.aws_network_interface.nlb-vlproxy-ingress-ips.private_ip}/32"]
}


