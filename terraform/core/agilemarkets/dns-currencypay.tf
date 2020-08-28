#
# Public record for Currencypay
#

resource "aws_route53_record" "currencypay" {
  zone_id = "${data.aws_route53_zone.nwm_zone.zone_id}"
  name    = "currencypay"
  type    = "A"
#TODO  health_check_id = "${aws_route53_health_check.agilemarkets_all_aggregated.id}"
  weighted_routing_policy {
    weight = 100
  }
  set_identifier = "${local.environment}-${local.region}"
  alias {
    name = "${aws_lb.alb-currencypay.dns_name}"
    zone_id = "${aws_lb.alb-currencypay.zone_id}"
    evaluate_target_health = true
 }
 lifecycle { ignore_changes = [ "weight" ] }
}
