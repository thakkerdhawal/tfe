###### CA API Gateway EC2 Instance
resource "aws_security_group" "apigw-sg" {
  description       = "Security Group for API GW EC2 instances"
  name        = "${local.environment}-apigw-sg"
  vpc_id      = "${data.aws_vpc.core.id}"
  tags = "${merge(local.default_tags, local.apigw_tags, map(
    "Name", "${local.environment}-apigw-sg"
  ))}"
}

resource "aws_security_group_rule" "apigw-ingress-agilemarkets-alb-traffic-https" {
  security_group_id = "${aws_security_group.apigw-sg.id}"
  type              = "ingress"
  description       = "Allow HTTPS access from the agilemarkets alb"
  from_port = "9443"
  to_port   = "9444"
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.agilemarkets-alb-sg.id}"
}

resource "aws_security_group_rule" "apigw-ingress-agilemarkets-internal-alb-traffic-https" {
  security_group_id = "${aws_security_group.apigw-sg.id}"
  type              = "ingress"
  description       = "Allow HTTPS access from the internal agilemarkets alb"
  from_port = "9443"
  to_port   = "9444"
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.agilemarkets-internal-alb-sg.id}"
}

resource "aws_security_group_rule" "apigw-ingress-currencypay-alb-traffic-https" {
  security_group_id = "${aws_security_group.apigw-sg.id}"
  type              = "ingress"
  description       = "Allow HTTPS access from the Currencypay alb"
  from_port = "9443"
  to_port   = "9444"
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.currencypay-alb-sg.id}"
}

# this rule is required because the Instances will be behind NLB
resource "aws_security_group_rule" "apigw-ingress-mgmt-https-ss" {
  security_group_id = "${aws_security_group.apigw-sg.id}"
  type              = "ingress"
  description       = "Allow HTTPS access to mgmt port from Shared Services"
  from_port = "8443"
  to_port   = "8443"
  protocol  = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.import.var.intra_subnets_cidr_blocks)}"]
}

resource "aws_security_group_rule" "apigw-egress-backend" {
   count = "${length(split(",",data.consul_keys.apigw.var.backends))}"
   security_group_id = "${aws_security_group.apigw-sg.id}"
   type              = "egress"
   description       = "Target Backends"
   from_port         = "${element(split(":",element(split(",",data.consul_keys.apigw.var.backends),count.index)),1)}"
   to_port           = "${element(split(":",element(split(",",data.consul_keys.apigw.var.backends),count.index)),1)}"
   protocol          = "tcp"
   cidr_blocks       =  ["${element(split(":",element(split(",",data.consul_keys.apigw.var.backends),count.index)),0)}"]
}

