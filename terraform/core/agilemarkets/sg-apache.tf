#### Security group for Apache #########
resource "aws_security_group" "apache-sg" {
  name        = "${local.environment}-apache-sg"
  description = "SG for Apache instances in ${local.environment}"
  vpc_id      = "${data.aws_vpc.core.id}"
  tags = "${merge(local.default_tags, local.apache_tags, map(
    "Name", "${local.environment}-apache-sg"
  ))}"
}

resource "aws_security_group_rule" "apache-ingress-https" {
  security_group_id = "${aws_security_group.apache-sg.id}"
  type              = "ingress"
  description       = "Allow connection to Apche Instances from ALB"
  from_port = 8443
  to_port   = 8443
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.agilemarkets-alb-sg.id}"
}

resource "aws_security_group_rule" "apache-egress-backends" {
  count = "${length(split(",",data.consul_keys.apache.var.backends))}"
  security_group_id = "${aws_security_group.apache-sg.id}"
  type              = "egress"
  description       = "Allow connection to RBS backends"
  from_port         = "${element(split(":",element(split(",",data.consul_keys.apache.var.backends),count.index)),1)}"
  to_port           = "${element(split(":",element(split(",",data.consul_keys.apache.var.backends),count.index)),1)}"
  protocol          = "tcp"
  cidr_blocks       =  ["${element(split(":",element(split(",",data.consul_keys.apache.var.backends),count.index)),0)}"]
}
