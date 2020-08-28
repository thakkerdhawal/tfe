# 
# The main ALB for Application Traffic through API Gateway and Apache
#
resource "aws_lb" "alb-agilemarkets" {
  name = "${local.environment}-agilemarkets-alb"
  load_balancer_type = "application"
  subnets = ["${data.aws_subnet_ids.public_subnets.ids}"]
  security_groups = ["${aws_security_group.agilemarkets-alb-sg.id}", "${aws_security_group.dnshealthcheck-sg.id}"]
  internal        = "false"
  access_logs {
    bucket  = "logging-${local.account_alias_core[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-agilemarkets-alb"
  ))}"
}

# Secure (HTTPS)
resource "aws_lb_listener" "listener-agilemarkets-https" {
  load_balancer_arn = "${aws_lb.alb-agilemarkets.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${data.consul_keys.v.var.agilemarket_www_cert.arn}"
  default_action {
    target_group_arn = "${aws_lb_target_group.tg-apigw.arn}"
    type             = "forward"
  }
}

# Insecure redirect (HTTP)
resource "aws_lb_listener" "listener-agilemarkets-http-redirect" {
  load_balancer_arn = "${aws_lb.alb-agilemarkets.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#
# Listener Rules
#

resource "aws_lb_listener_rule" "ssg-404" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 2

  action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code = "404"
    }
  }

  condition {
    field  = "path-pattern"
    values = ["/ssg/*"]
  }
}

resource "aws_lb_listener_rule" "restman-404" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 3

  action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code = "404"
    }
  }

  condition {
    field  = "path-pattern"
    values = ["/restman/*"]
  }
}

resource "aws_lb_listener_rule" "wsman-404" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 4

  action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code = "404"
    }
  }

  condition {
    field  = "path-pattern"
    values = ["/wsman/*"]
  }
}

resource "aws_lb_listener_rule" "autologon-404" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 5

  action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code = "404"
    }
  }

  condition {
    field  = "path-pattern"
    values = ["/v4logon/v1/auto*"]
  }
}

resource "aws_lb_listener_rule" "admin-redirect" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 6

  action {
    type             = "redirect"
    redirect {
      path = "/"
      query = ""
      status_code = "HTTP_301"
    }
  }

  condition {
    field  = "path-pattern"
    values = ["/admin*"]
  }
}

resource "aws_lb_listener_rule" "agile-prime-upload" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg-apache-agilemarkets.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/api/prime/*/Upload/*"]
  }
}

resource "aws_lb_listener_rule" "agile-spreadsheet" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg-apache-agilemarkets.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/api/spreadsheet/*"]
  }
}

resource "aws_lb_listener_rule" "agile-fut-upload" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg-apache-agilemarkets.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/api/futures/v1/reports/download/*"]
  }
}

resource "aws_lb_listener_rule" "agile-ats-interfaces-load" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg-apache-agilemarkets.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/api/atsint/*/interfaces/load/*"]
  }
}

resource "aws_lb_listener_rule" "agile-ats-upload" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg-apache-agilemarkets.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/api/atsint/*/upload-doc/*"]
  }
}

resource "aws_lb_listener_rule" "agile-ats-portfolio" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg-apache-agilemarkets.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/api/atsint/*/portfolio-based/load/*"]
  }
}

resource "aws_lb_listener_rule" "agile-v4logon" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 70

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg-apache-agilemarkets.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/v4logon/*"]
  }
}

resource "aws_lb_listener_rule" "agile-logon" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 80

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg-apache-agilemarkets.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/logon/*"]
  }
}

resource "aws_lb_listener_rule" "agile-ats-prism-upload" {
  listener_arn = "${aws_lb_listener.listener-agilemarkets-https.arn}"
  priority     = 90

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.tg-apache-agilemarkets.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/api/prism/v1/main/file/provider/*"]
  }
}

#
# Target Groups
#

# Layer 7 Target Group
resource "aws_lb_target_group" "tg-apigw" {
  name = "${local.environment}-apigw-tg"
  port = 9443
  protocol = "HTTPS"
  vpc_id = "${data.aws_vpc.core.id}"
  health_check {
    interval = 30
    timeout = 2
    healthy_threshold = 3
    unhealthy_threshold = 2
    port = "9444"
    protocol = "HTTPS"
    path = "/ssg/ping"
    matcher = 200
  }
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-apigw-tg"
  ))}"
}

resource "aws_lb_target_group_attachment" "attach-apigw" {
  count            = "${data.consul_keys.apigw.var.instance_count}"
  target_group_arn = "${aws_lb_target_group.tg-apigw.arn}"
  target_id        = "${element(aws_instance.apigw.*.id, count.index)}"
  port             = 9443
}

# Apache Target Group

resource "aws_lb_target_group" "tg-apache-agilemarkets" {
  name = "${local.environment}-apache-agilem-tg"
  port = 8443
  protocol = "HTTPS"
  vpc_id = "${data.aws_vpc.core.id}"
  health_check {
    interval = 15
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 2
    port = "8443"
    protocol = "HTTPS"
    path = "/"
    matcher = 200
  }
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-apache-tg"
  ))}"
}

resource "aws_lb_target_group_attachment" "attach-apache-agilemarkets" {
  count = "${element(split(",",data.consul_keys.apache.var.instance_count),0)}"
  target_group_arn = "${aws_lb_target_group.tg-apache-agilemarkets.arn}"
  target_id        = "${element(aws_instance.apache.*.id, count.index)}"
  port             = 8443
}


#
# Internal ALB for Agilemarkets TopicEnabler
#
resource "aws_lb" "alb-agilemarkets-internal" {
  name = "${local.environment}-agilemarkets-int-alb"
  load_balancer_type = "application"
  subnets = ["${data.aws_subnet_ids.intra_subnets.ids}"]
  security_groups = ["${aws_security_group.agilemarkets-internal-alb-sg.id}"]
  internal        = "true"
  access_logs {
    bucket  = "logging-${local.account_alias_core[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-agilemarkets-internal-topicenabler-alb"
  ))}"
}

resource "aws_lb_listener" "listener-agilemarkets-internal-https" {
  load_balancer_arn = "${aws_lb.alb-agilemarkets-internal.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${data.consul_keys.v.var.agilemarket_www_cert.arn}"
  default_action {
    target_group_arn = "${aws_lb_target_group.tg-apigw-internal.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "tg-apigw-internal" {
  name = "${local.environment}-apigw-internal-tg"
  port = 9443
  protocol = "HTTPS"
  vpc_id = "${data.aws_vpc.core.id}"
  health_check {
    interval = 30
    timeout = 2
    healthy_threshold = 3
    unhealthy_threshold = 2
    port = "9444"
    protocol = "HTTPS"
    path = "/ssg/ping"
    matcher = 200
  }
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-apigw-internal-tg"
  ))}"
}

resource "aws_lb_target_group_attachment" "attach-apigw-internal" {
  count            = "${data.consul_keys.apigw.var.instance_count}"
  target_group_arn = "${aws_lb_target_group.tg-apigw-internal.arn}"
  target_id        = "${element(aws_instance.apigw.*.id, count.index)}"
  port             = 9443
}

