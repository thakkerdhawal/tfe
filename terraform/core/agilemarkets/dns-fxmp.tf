#
# Public record used only by NLB to provide multi-dc
#

resource "aws_route53_record" "fxmp-uk-external" {
  zone_id = "${data.aws_route53_zone.fxmp_www_zone.zone_id}"
  name    = "fxmp-uk"
  type    = "A"
  health_check_id = "${aws_route53_health_check.apigw.id}"
  weighted_routing_policy {
    weight = 100
  }
  set_identifier = "${local.environment}-${local.region}"
  alias {
    name = "${aws_lb.nlb-fxmp-uk.dns_name}"
    zone_id = "${aws_lb.nlb-fxmp-uk.zone_id}"
    evaluate_target_health = true
  }
  lifecycle { ignore_changes = [ "weight" ] }
}

resource "aws_route53_record" "fxmp-us-external" {
  zone_id = "${data.aws_route53_zone.fxmp_www_zone.zone_id}"
  name    = "fxmp-us"
  type    = "A"
  health_check_id = "${aws_route53_health_check.apigw.id}"
  weighted_routing_policy {
    weight = 100
  }
  set_identifier = "${local.environment}-${local.region}"
  alias {
    name = "${aws_lb.nlb-fxmp-us.dns_name}"
    zone_id = "${aws_lb.nlb-fxmp-us.zone_id}"
    evaluate_target_health = true
  }
  lifecycle { ignore_changes = [ "weight" ] }
}

resource "aws_route53_record" "fxmp-int-uk-external" {
  count = "${ local.environment == "prod"? 1:0 }"
  zone_id = "${data.aws_route53_zone.fxmp_www_zone.zone_id}"
  name    = "fxmp-int-uk"
  type    = "A"
  health_check_id = "${aws_route53_health_check.apigw.id}"
  weighted_routing_policy {
    weight = 100
  }
  set_identifier = "${local.environment}-${local.region}"
  alias {
    name = "${aws_lb.nlb-fxmp-int-uk.dns_name}"
    zone_id = "${aws_lb.nlb-fxmp-int-uk.zone_id}"
    evaluate_target_health = true
  }
  lifecycle { ignore_changes = [ "weight" ] }
}
resource "aws_route53_record" "fxmp-int-us-external" {
  count = "${ local.environment == "prod"? 1:0 }"
  zone_id = "${data.aws_route53_zone.fxmp_www_zone.zone_id}"
  name    = "fxmp-int-us"
  type    = "A"
  health_check_id = "${aws_route53_health_check.apigw.id}"
  weighted_routing_policy {
    weight = 100
  }
  set_identifier = "${local.environment}-${local.region}"
  alias {
    name = "${aws_lb.nlb-fxmp-int-us.dns_name}"
    zone_id = "${aws_lb.nlb-fxmp-int-us.zone_id}"
    evaluate_target_health = true
  }
  lifecycle { ignore_changes = [ "weight" ] }
}
