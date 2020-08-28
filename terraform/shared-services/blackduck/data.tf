data "aws_route53_zone" "dns_zone" {
  name = "${data.consul_keys.blackduck.var.dns_zone}."
}

