data "aws_network_interface" "fxmp-int-uk-apigw-nlb" {
  count = "${ local.environment == "prod"? length(data.aws_subnet_ids.public_subnets.ids):0 }"
  filter = {
    name   = "description"
    values = ["ELB net/${local.environment}-fxmp-int-uk-nlb/*"]
  }
  filter = {
    name   = "subnet-id"
    # Below is to work around broken Terraform Dependencies. The ARN will never match but it adds dependency without using the depends_on argument
    values = ["${element(data.aws_subnet_ids.public_subnets.ids, count.index)}","${aws_lb.nlb-fxmp-int-uk.arn}"]
  }
}

#
# Update APIGW SG for FXMP INT
#

resource "aws_security_group_rule" "fxmp-int-uk-apigw-ingress-traffic" {
  count = "${ local.environment == "prod"? 1:0 }"
  type            = "ingress"
  from_port       = "9603"
  to_port         = "9603"
  protocol        = "tcp"
  cidr_blocks = ["${split(",",data.consul_keys.fxmp.var.public_alb_allowed_cidrs)}"]
  description       = "Allow request from fxmp-int-uk APIGW NLB"
  security_group_id = "${aws_security_group.apigw-sg.id}"
}

