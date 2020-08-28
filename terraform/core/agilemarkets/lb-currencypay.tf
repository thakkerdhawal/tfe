#
# The main ALB for Application Traffic through API Gateway
#
resource "aws_lb" "alb-currencypay" {
  name = "${local.environment}-currencypay-alb"
  load_balancer_type = "application"
  subnets = ["${data.aws_subnet_ids.public_subnets.ids}"]
  security_groups = ["${aws_security_group.currencypay-alb-sg.id}", "${aws_security_group.dnshealthcheck-sg.id}"]
  internal        = "false"
  access_logs {
    bucket  = "logging-${local.account_alias_core[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  tags = "${merge(local.default_tags, local.currencypay_tags,  map(
    "Name", "${local.environment}-currencypay-alb"
  ))}"
}

# Secure (HTTPS)
resource "aws_lb_listener" "listener-currencypay-https" {
  load_balancer_arn = "${aws_lb.alb-currencypay.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${data.consul_keys.currencypay.var.currencypay_cert.arn}"
  default_action {
    target_group_arn = "${aws_lb_target_group.tg-apigw-currencypay.arn}"
    type             = "forward"
  }
}

# Insecure redirect (HTTP)
resource "aws_lb_listener" "listener-currencypay-http-redirect" {
  load_balancer_arn = "${aws_lb.alb-currencypay.arn}"
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
# Target Groups
#

# Layer 7 Target Group
resource "aws_lb_target_group" "tg-apigw-currencypay" {
  name = "${local.environment}-apigw-currencypay-tg"
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
  tags = "${merge(local.default_tags, local.currencypay_tags, map(
    "Name", "${local.environment}-apigw-currencypay-tg"
  ))}"
}

resource "aws_lb_target_group_attachment" "attach-apigw-currencypay" {
  count            = "${data.consul_keys.apigw.var.instance_count}"
  target_group_arn = "${aws_lb_target_group.tg-apigw-currencypay.arn}"
  target_id        = "${element(aws_instance.apigw.*.id, count.index)}"
  port             = 9443
}
