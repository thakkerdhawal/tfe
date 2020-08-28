resource "aws_route53_record" "stream_dnsrecord_agilemarkets" {
  count   = "${data.consul_keys.stream.var.stream_instance_count}"
  zone_id = "${data.aws_route53_zone.am_zone.zone_id}"
  name    = "stream${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}"
  type    = "A"
  alias {
    name = "${element(aws_lb.alb-stream-agilemarkets.*.dns_name, count.index)}"
    zone_id = "${element(aws_lb.alb-stream-agilemarkets.*.zone_id, count.index)}"
    evaluate_target_health = true
  }
}

