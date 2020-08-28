# NLB for FXMP US
resource "aws_lb" "nlb-fxmp-us" {
  name            = "${local.environment}-fxmp-us-nlb"
  internal        = false
  enable_cross_zone_load_balancing = true
  load_balancer_type = "network"
  access_logs {
    bucket  = "logging-${local.account_alias_core[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  subnet_mapping {
    subnet_id     = "${element(data.aws_subnet_ids.public_subnets.ids,0)}"
    allocation_id = "${data.aws_eip.fxmp-us.0.id}"
  }
  subnet_mapping {
    subnet_id     = "${element(data.aws_subnet_ids.public_subnets.ids,1)}"
    allocation_id = "${data.aws_eip.fxmp-us.1.id}"
  }
  subnet_mapping {
    subnet_id     = "${element(data.aws_subnet_ids.public_subnets.ids,2)}"
    allocation_id = "${data.aws_eip.fxmp-us.2.id}"
  }
  tags = "${merge(local.default_tags, local.fxmp_tags, map(
    "Name", "${local.environment}-fxmp-us-nlb"
  ))}"
}

resource "aws_lb_target_group" "tg-fxmp-us" {
  name = "${local.environment}-fxmp-us-tg"
  target_type = "instance"
  port = 9602
  protocol = "TCP"
  vpc_id = "${data.aws_vpc.core.id}"
  health_check {
    interval = 10
    healthy_threshold = 3
    port = "traffic-port"
    protocol = "TCP"
  }
}

resource "aws_lb_target_group_attachment" "attach-fxmp-us" {
  count         = "${data.consul_keys.apigw.var.instance_count}"
  target_group_arn = "${aws_lb_target_group.tg-fxmp-us.arn}"
  target_id        = "${element(aws_instance.apigw.*.id, count.index)}"
  port             = 9602
}

resource "aws_lb_listener" "listener-fxmp-us-https" {
  load_balancer_arn = "${aws_lb.nlb-fxmp-us.arn}"
  port              = "443"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.tg-fxmp-us.arn}"
    type             = "forward"
  }
}

