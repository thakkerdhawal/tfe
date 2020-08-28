#
# External ALB
#
resource "aws_lb" "blackduck" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  name = "${local.environment}-blackduck-alb"
  load_balancer_type = "application"
  access_logs {
    bucket  = "logging-${local.account_alias_shared-services[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  subnets=["${split(",",data.consul_keys.import.var.public_subnets)}"]
  security_groups = ["${aws_security_group.blackduck-hub-lb-sg.id}"]
  internal        = "false"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck-alb"
  ))}"
}

resource "aws_lb_target_group" "blackduck" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  name = "${local.environment}-blackduck-tg"
  port = 443
  protocol = "HTTPS"
  vpc_id   = "${data.consul_keys.import.var.vpc_id}"
  health_check {
    interval = 15
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 2
    port = "traffic-port"
    protocol = "HTTPS"
    path = "/"
    matcher = 200
  }
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck-tg"
  ))}"
}

resource "aws_lb_target_group_attachment" "blackduck" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  target_group_arn = "${aws_lb_target_group.blackduck.arn}"
  target_id        = "${aws_instance.blackduck-hub.id}"
  port             = 443
}

resource "aws_lb_listener" "listener-blackduck-https" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  load_balancer_arn = "${aws_lb.blackduck.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = "${data.consul_keys.blackduck.var.blackduck_cert_arn}"
  default_action {
    target_group_arn = "${aws_lb_target_group.blackduck.arn}"
    type             = "forward"
  }
}

#
# Internal ALB
#
resource "aws_lb" "blackduck-int" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  name = "${local.environment}-blackduck-int-alb"
  load_balancer_type = "application"
  access_logs {
    bucket  = "logging-${local.account_alias_shared-services[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  subnets=["${split(",",data.consul_keys.import.var.intra_subnets)}"]
  security_groups = ["${aws_security_group.blackduck-int-lb-sg.id}"]
  internal        = "true"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck-int-alb"
  ))}"
}

resource "aws_lb_target_group" "blackduck-int" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  name = "${local.environment}-blackduck-int-tg"
  port = 443
  protocol = "HTTPS"
  vpc_id   = "${data.consul_keys.import.var.vpc_id}"
  health_check {
    interval = 15
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 2
    port = "traffic-port"
    protocol = "HTTPS"
    path = "/"
    matcher = 200
  }
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck-int-tg"
  ))}"
}

resource "aws_lb_target_group_attachment" "blackduck-int" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  target_group_arn = "${aws_lb_target_group.blackduck-int.arn}"
  target_id        = "${aws_instance.blackduck-hub.id}"
  port             = 443
}

resource "aws_lb_listener" "listener-blackduck-int-https" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  load_balancer_arn = "${aws_lb.blackduck-int.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = "${data.consul_keys.blackduck.var.blackduck_internal_cert_arn}"
  default_action {
    target_group_arn = "${aws_lb_target_group.blackduck-int.arn}"
    type             = "forward"
  }
}
