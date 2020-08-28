#
# Create a generic security group that can be used by all ec2 instances
# Provides ingress ssh access from the bastion host(s)
# No permitted egress rule by default
#
# TODO: we allow both CTO and NWM Bastion hosts connection for now. Should only have one in the future.
#

resource "aws_security_group" "all-hosts-sg" {
  name        = "${local.environment}-all-hosts-sg"
  description = "SG for all nodes"
  vpc_id      = "${module.vpcnwm.vpc_id}"
  depends_on = ["aws_vpc_peering_connection_accepter.accepter-nwmss-core-vpc"]
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-all-hosts-sg"
  ))}"

}

resource "aws_security_group_rule" "all-hosts-ingress-cto-ssh" {
  security_group_id = "${aws_security_group.all-hosts-sg.id}"
  type              = "ingress"
  description       = "Allow SSH access from CTO bastion hosts"
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = ["${data.consul_keys.v.var.cto_subnet}"]
}

resource "aws_security_group_rule" "all-hosts-ingress-ssh" {
  security_group_id = "${aws_security_group.all-hosts-sg.id}"
  type              = "ingress"
  description       = "Allow SSH access from NWM bastion host"
  from_port = "22"
  to_port   = "22"
  protocol  = "tcp"
  source_security_group_id = "${data.consul_keys.import.var.bastion_hosts_sg_id}"
}
 
resource "aws_security_group_rule" "all-hosts-egress-aws-vpc-endpoint" {
  security_group_id = "${aws_security_group.all-hosts-sg.id}"
  type              = "egress"
  description       = "Allow outbound HTTPS connection to AWS VPC Endpoint (For Cloudwatch etc)" 
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.aws-vpc-endpoint-sg.id}"
}

#
# Security group for the AWS VPC Endpoint Interfaces (For Cloudwatch, ec2 etc AWS Service access from Intra subnets)
#
resource "aws_security_group" "aws-vpc-endpoint-sg" {
  name        = "${local.environment}-aws-vpc-endpoint-sg"
  description = "SG for AWS VPC Endpoint Interfaces"
  vpc_id      = "${module.vpcnwm.vpc_id}"

  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-aws-vpc-endpoint-sg"
  ))}"
}

resource "aws_security_group_rule" "aws-vpc-endpoint-ingress-https" {
  security_group_id = "${aws_security_group.aws-vpc-endpoint-sg.id}"
  type              = "ingress"
  description       = "Allow HTTPS access from all EC2 instances"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
  source_security_group_id = "${aws_security_group.all-hosts-sg.id}"
}
# egress rule not required for cwlogs endpoint

# Take default sg under tf control with no rule set.
resource "aws_default_security_group" "default" {
  vpc_id         = "${module.vpcnwm.vpc_id}" 
}
