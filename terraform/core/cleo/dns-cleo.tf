### Create DNS record for vlproxyInbound ###
resource "aws_route53_record" "vlproxydnsrecord" {
  zone_id = "${data.aws_route53_zone.vlproxy_zone.zone_id}"
  name    = "filetransfer"
  type    = "A"
  set_identifier = "${local.environment}-${local.region}"
  health_check_id = "${aws_route53_health_check.vlproxy-ingress-healthcheck.id}"
  alias {
    name = "${aws_lb.nlb-vlproxy-ingress.dns_name}"
    zone_id = "${aws_lb.nlb-vlproxy-ingress.zone_id}"
    evaluate_target_health = true
  }
  weighted_routing_policy {
    weight = 100
  }
  lifecycle { ignore_changes = [ "weight" ] }  
}

resource "aws_route53_health_check" "vlproxy-ingress-healthcheck" {
  fqdn              = "${aws_lb.nlb-vlproxy-ingress.dns_name}"
  port              = "22"
  type              = "TCP"
  failure_threshold = "5"
  measure_latency = "true"
  request_interval = "30"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-${local.region}-vlproxy-ingress-healthcheck"
  ))}"
}

