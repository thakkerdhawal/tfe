#
# Internal ALB for a dummy Splunk instance in LAB or CICD
#
resource "aws_lb" "lb-splunk-web-int" {
  count = "${ local.environment == "lab" ? 1:0 }"
  name = "${local.environment}-splunk-web-int-alb"
  load_balancer_type = "application"
  subnets=["${data.aws_subnet_ids.intra_subnets.ids}"]
  security_groups = ["${aws_security_group.splunk-web-int-lb-sg.id}"]
  internal        = "true"
  access_logs {
    bucket  = "logging-${local.account_alias_shared-services[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-splunk-web-int-alb"
  ))}"
}

resource "aws_lb_target_group" "tg-splunk-web-int" {
  count = "${ local.environment == "lab" ? 1:0 }"
  name = "${local.environment}-splunk-web-int-tg"
  port = 443
  protocol = "HTTPS"
  vpc_id   = "${data.aws_vpc.ss.id}"
  health_check {
    interval = 30
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 2
    port = "traffic-port"
    protocol = "HTTPS"
    path = "/"
    matcher = 200
  }
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-splunk-web-int-tg"
  ))}"
}

resource "aws_lb_target_group_attachment" "attach-splunk-web-int" {
  count = "${ local.environment == "lab" ? 1:0 }"
  target_group_arn = "${aws_lb_target_group.tg-splunk-web-int.arn}"
  target_id        = "${aws_instance.splunk-web.id}"
  port             = 8443
}

resource "aws_lb_listener" "listener-splunk-web-int-https" {
  count = "${ local.environment == "lab" ? 1:0 }"
  load_balancer_arn = "${aws_lb.lb-splunk-web-int.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  # certificate_arn   = "${data.consul_keys.logging.var.splunk_internal_cert_arn}"
  certificate_arn = "${data.aws_acm_certificate.splunk-cert.arn}"
  default_action {
    target_group_arn = "${aws_lb_target_group.tg-splunk-web-int.arn}"
    type             = "forward"
  }
}
