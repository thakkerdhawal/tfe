data "aws_network_interface" "fxmp-us-apigw-nlb" {
  count = "${length(data.aws_subnet_ids.public_subnets.ids)}"
  filter = {
    name   = "description"
    values = ["ELB net/${local.environment}-fxmp-us-nlb/*"]
  }
  filter = {
    name   = "subnet-id"
    # Below is to work around broken Terraform Dependencies. The ARN will never match but it adds dependency without using the depends_on argument
    values = ["${element(data.aws_subnet_ids.public_subnets.ids, count.index)}","${aws_lb.nlb-fxmp-us.arn}"]
  }
}

#
# Update APIGW SG for FXMP US
#

resource "aws_security_group_rule" "fxmp-us-apigw-ingress-traffic" {
  type            = "ingress"
  from_port       = "9602"
  to_port         = "9602"
  protocol        = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.fxmp.var.public_alb_allowed_cidrs)}"]
  description       = "Allow request from fxmp-us APIGW NLB"
  security_group_id = "${aws_security_group.apigw-sg.id}"
}

