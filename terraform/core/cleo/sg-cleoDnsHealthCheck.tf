# Allow all traffic from dnshealthcheck ip ranges
data "aws_ip_ranges" "dnshealthcheck" {
  services = ["route53_healthchecks"]
}

resource "aws_security_group" "vlproxy-dnshealthcheck-sg" {
  name        = "${local.environment}-vlproxy-dnshealthcheck-sg"
  description = "${local.environment} Cleo VLProxy dnshealthcheck Security Group"
  vpc_id      = "${data.aws_vpc.core.id}"

  ingress {
    from_port   = 9022
    to_port     = 9022
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_ip_ranges.dnshealthcheck.cidr_blocks}"]
  }

  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-vlproxy-dnshealthcheck-sg"
  ))}"
}
