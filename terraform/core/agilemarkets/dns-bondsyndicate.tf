#
# Public record used only by Cloudfront to provide multi-dc
#

resource "aws_route53_record" "bondsyndicate_dns_glue_record" {
  zone_id = "${data.aws_route53_zone.nwm_zone.zone_id}"
  name    = "syndicate"
  type    = "A"
  health_check_id = "${aws_route53_health_check.internal_dnshealthcheck_bondsyndicate.id}"
  weighted_routing_policy {
    weight = 100
  }
  set_identifier = "${local.environment}-${local.region}"
  alias {
    name = "${aws_lb.alb-bondsyndicate.dns_name}"
    zone_id = "${aws_lb.alb-bondsyndicate.zone_id}"
    evaluate_target_health = true
 }
 lifecycle { ignore_changes = [ "weight" ] }
}

#
# DNS health checks for internal AM DNS
#

# TODO These health checks need to be updated for Bond Syndicate
resource "aws_route53_health_check" "internal_dnshealthcheck_bondsyndicate" {
  fqdn              = "${aws_lb.alb-bondsyndicate.dns_name}"
  port              = 443 
  type              = "HTTPS"
  resource_path     = "/pda.do"
  failure_threshold = "5"
  measure_latency = true
  request_interval  = "30"
  tags = "${merge(local.default_tags, local.bondsyndicate_tags,  map(
    "Name", "${local.environment}-${local.region}-internal-health-check-bondsyndicate"
  ))}"
}

