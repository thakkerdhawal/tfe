# Agilemarkets Liberator ALBs
resource "aws_lb" "alb-stream-agilemarkets" {
  count              = "${data.consul_keys.stream.var.stream_instance_count}"
  name               = "${local.environment}-stream${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}-alb"
  internal           = "false"
  load_balancer_type = "application"
  access_logs {
    bucket  = "logging-${local.account_alias_core[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  subnets            = ["${data.aws_subnet_ids.public_subnets.ids}"]
  security_groups    = ["${aws_security_group.stream-alb-sg.id}"]
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-stream${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}-alb"
  ))}"
}

resource "aws_lb_target_group" "tg-stream-agilemarkets" {
  count    = "${data.consul_keys.stream.var.stream_instance_count}"
  name     = "${local.environment}-stream${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}-tg"
  port     = "4447"
  protocol = "HTTPS"
  vpc_id   = "${data.aws_vpc.core.id}"
  health_check {
    interval = 30
    healthy_threshold = 3
    port = "traffic-port"
    protocol = "HTTPS"
    path = "/"
  }
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-stream${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}-tg"
  ))}"
}

resource "aws_lb_target_group_attachment" "attach-stream-agilemarkets" {
  count            = "${data.consul_keys.stream.var.stream_instance_count}"
  target_group_arn = "${element(aws_lb_target_group.tg-stream-agilemarkets.*.arn, count.index)}"
  target_id        = "${element(aws_instance.stream.*.id, count.index)}"
  port             = "4447"
}

resource "aws_lb_listener" "listener-stream-https-agilemarkets" {
  count             = "${data.consul_keys.stream.var.stream_instance_count}"
  load_balancer_arn = "${element(aws_lb.alb-stream-agilemarkets.*.arn, count.index)}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${element(split(",",data.consul_keys.stream.var.stream_certs_agilemarkets.arns),count.index)}"
  default_action {
    target_group_arn = "${element(aws_lb_target_group.tg-stream-agilemarkets.*.arn, count.index)}"
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "alb-stream-agilemarkets-status-block" {
  count        = "${data.consul_keys.stream.var.stream_instance_count}"
  listener_arn = "${element(aws_lb_listener.listener-stream-https-agilemarkets.*.arn, count.index)}"
  priority     = 1

  action {
    type = "redirect"
    redirect {
      path = "/"
      query = ""
      status_code = "HTTP_301"
    }
  }

  condition {
    field  = "path-pattern"
    values = ["/status/*"]
  }
}

