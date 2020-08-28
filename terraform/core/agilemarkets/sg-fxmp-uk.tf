data "aws_network_interface" "fxmp-uk-apigw-nlb" {
  count = "${length(data.aws_subnet_ids.public_subnets.ids)}"
  filter = {
    name   = "description"
    values = ["ELB net/${local.environment}-fxmp-uk-nlb/*"]
  }
  filter = {
    name   = "subnet-id"
    # Below is to work around broken Terraform Dependencies. The ARN will never match but it adds dependency without using the depends_on argument
    values = ["${element(data.aws_subnet_ids.public_subnets.ids, count.index)}", "${aws_lb.nlb-fxmp-uk.arn}"]
  }
}

#
# Update APIGW SG for FXMP UK
#

resource "aws_security_group_rule" "fxmp-uk-apigw-ingress-traffic" {
  type            = "ingress"
  from_port       = "9601"
  to_port         = "9601"
  protocol        = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.fxmp.var.public_alb_allowed_cidrs)}"]
  description       = "Allow request from fxmp-uk APIGW NLB"
  security_group_id = "${aws_security_group.apigw-sg.id}"
}

