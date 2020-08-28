
resource "aws_route53_record" "dnsrecord" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  zone_id = "${data.aws_route53_zone.dns_zone.zone_id}"
  name    = "${data.consul_keys.blackduck.var.blackduck_dns}"
  type    = "A"
  alias {
    name = "${aws_lb.blackduck.dns_name}"
    zone_id = "${aws_lb.blackduck.zone_id}"
    evaluate_target_health = true
  }
}

