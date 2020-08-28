# Allow all traffic from dnshealthcheck ip ranges
data "aws_ip_ranges" "dnshealthcheck" {
  services = ["route53_healthchecks"]
}

resource "aws_security_group" "dnshealthcheck-sg" {
  name        = "${local.environment}-dnshealthcheck-sg"
  description = "${local.environment} dnshealthcheck Security Group"
  vpc_id      = "${data.aws_vpc.core.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_ip_ranges.dnshealthcheck.cidr_blocks}"]
  }

  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-dnshealthcheck-sg"
  ))}"
}

