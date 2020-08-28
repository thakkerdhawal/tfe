#
# Public record used only by Cloudfront to provide multi-dc 
#

resource "aws_route53_record" "agilemarkets_dns_glue_record" {
  zone_id = "${data.aws_route53_zone.am_zone.zone_id}"
  name    = "www"
  type    = "A"
  health_check_id = "${aws_route53_health_check.agilemarkets_all_aggregated.id}"
  weighted_routing_policy {
    weight = 100
  }
  set_identifier = "${local.environment}-${local.region}"
  alias {
    name = "${aws_lb.alb-agilemarkets.dns_name}"
    zone_id = "${aws_lb.alb-agilemarkets.zone_id}"
    evaluate_target_health = true
  }
  lifecycle { ignore_changes = [ "weight" ] }
}
#
# We have two groups of health checks. 
# 1) Test that APIGW is healthy (Only 1 check has to be healthy)
# 2) Test a number of ping URLs for the application (Muliple checks and at least 1 has to be health). The intent of this check is to make sure CNF connectivity back to campus is ok.
# The DNS check is considered healthy when both these conditions are met
#
# Note that you can't nest aggregate health checks so to trigger on the aggregate URL healthcheck
# we are using a cloudwatch alarm then watching the health of that alarm

# Route53 health check for APIGW (Check 1)
resource "aws_route53_health_check" "apigw" {
  fqdn              = "${aws_lb.alb-agilemarkets.dns_name}"
  port              = 443 
  type              = "HTTPS"
  resource_path     = "/check/wsg/local"
  failure_threshold = "3"
  measure_latency   = true
  request_interval  = "30"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-${local.region}-apigw-alb"
  ))}"
  lifecycle { create_before_destroy = true }
}

# Route53 health checks for internal AM Services (Check 2)
resource "aws_route53_health_check" "agilemarkets_url" {
  count             = "${length(split(",",data.consul_keys.v.var.internal_dnshealthcheck_urls))}"
  fqdn              = "${aws_lb.alb-agilemarkets.dns_name}"
  port              = 443 
  type              = "HTTPS"
  resource_path     = "${element(split(":",element(split(",",data.consul_keys.v.var.internal_dnshealthcheck_urls),count.index)),1)}"
  failure_threshold = "3"
  measure_latency = true
  request_interval  = "30"
  tags = "${merge(local.default_tags, local.agilemarkets_tags,  map(
    "Name", "${local.environment}-${local.region}-agilemarkets-alb-url-${count.index + 1}"
  ))}"
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_health_check" "agilemarkets_urls_aggregated" {
  type                   = "CALCULATED"
  child_healthchecks     = ["${aws_route53_health_check.agilemarkets_url.*.id}"]
  child_health_threshold = "1"
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-${local.region}-agilemarkets-alb-urls-aggregate"
  ))}"
}

resource "aws_cloudwatch_metric_alarm" "route53_healthcheck_agilemarkets_urls_aggregated" {
  provider            = "aws.us-east-1"
  alarm_name          = "${local.environment}-${local.region}-r53-healthcheck-agilemarkets-urls"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  period              = "60"
  threshold           = "1"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  statistic           = "Average"
  alarm_description   = "This metric monitors Agilemarkets URLs Route53 Health check"
  dimensions = {
    HealthCheckId = "${aws_route53_health_check.agilemarkets_urls_aggregated.id}"
  }
}

resource "aws_route53_health_check" "agilemarkets_urls_cloudwatch_alarm" {
  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = "${aws_cloudwatch_metric_alarm.route53_healthcheck_agilemarkets_urls_aggregated.alarm_name}"
  cloudwatch_alarm_region         = "us-east-1"
  insufficient_data_health_status = "Unhealthy"
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-${local.region}-agilemarkets-alb-urls-cloudwatch-alarm"
  ))}"
}


# Route53 health checks aggregate (Check 1 + Check 2)
resource "aws_route53_health_check" "agilemarkets_all_aggregated" {
  type                   = "CALCULATED"
  child_healthchecks     = ["${aws_route53_health_check.agilemarkets_urls_cloudwatch_alarm.id}", "${aws_route53_health_check.apigw.id}"]
  child_health_threshold = "2"
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-${local.region}-agilemarkets-alb-aggregate-all"
  ))}"
}


#
# Private VPC Zones and Records
#
resource "aws_route53_zone" "private_agilemarkets" {
  name = "${replace(element(split(",",data.consul_keys.v.var.agilemarkets_dns_external),0),"/^(.+?\\.)(.*)/","$2")}"
  force_destroy = true
  vpc {
    vpc_id = "${data.aws_vpc.core.id}"
  }
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-private-agilemarkets-zone"
  ))}"
}

resource "aws_route53_record" "private_wwwdnsrecord" {
  zone_id = "${aws_route53_zone.private_agilemarkets.zone_id}"
  name    = "${element(split(",",data.consul_keys.v.var.agilemarkets_dns_external),0)}"
  type    = "A"
  alias {
    name = "${aws_lb.alb-agilemarkets-internal.dns_name}"
    zone_id = "${aws_lb.alb-agilemarkets-internal.zone_id}"
    evaluate_target_health = false
 }
}

