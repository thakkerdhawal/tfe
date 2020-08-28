# 
# The main ALB for Bond Syndicate
#
resource "aws_lb" "alb-bondsyndicate" {
  name = "${local.environment}-bondsyndicate-alb"
  load_balancer_type = "application"
  subnets = ["${data.aws_subnet_ids.public_subnets.ids}"]
  security_groups = ["${aws_security_group.bondsyndicate-alb-sg.id}", "${aws_security_group.dnshealthcheck-sg.id}"]
  internal        = "false"
  access_logs {
    bucket  = "logging-${local.account_alias_core[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  tags = "${merge(local.default_tags, local.bondsyndicate_tags, map(
    "Name", "${local.environment}-bondsyndicate-alb"
  ))}"
}

# Secure (HTTPS)
resource "aws_lb_listener" "listener-bondsyndicate-https" {
  load_balancer_arn = "${aws_lb.alb-bondsyndicate.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${data.consul_keys.bondsyndicate.var.bondsyndicate_cert.arn}"
  default_action {
    target_group_arn = "${aws_lb_target_group.tg-apache-bondsyndicate.arn}"
    type             = "forward"
  }
}

# Insecure redirect (HTTP)
resource "aws_lb_listener" "listener-bondsyndicate-http-redirect" {
  load_balancer_arn = "${aws_lb.alb-bondsyndicate.arn}"
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

# Apache Target Group

resource "aws_lb_target_group" "tg-apache-bondsyndicate" {
  name = "${local.environment}-apache-bonds-tg"
  port = 8444
  protocol = "HTTPS"
  vpc_id = "${data.aws_vpc.core.id}"
  health_check {
    interval = 15
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 2
    port = "8444"
    protocol = "HTTPS"
    path = "/pda.do"
    matcher = 200
  }
  tags = "${merge(local.default_tags, local.bondsyndicate_tags, map(
    "Name", "${local.environment}-apache-bondsyndicate-tg"
  ))}"
}

resource "aws_lb_target_group_attachment" "attach-apache-bondsyndicate" {
  count = "${element(split(",",data.consul_keys.apache.var.instance_count),0)}"
  target_group_arn = "${aws_lb_target_group.tg-apache-bondsyndicate.arn}"
  target_id        = "${element(aws_instance.apache.*.id, count.index)}"
  port             = 8444
}

