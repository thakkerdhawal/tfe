# NLB for FXMP UK integration (in Prod)
resource "aws_lb" "nlb-fxmp-int-uk" {
  count = "${ local.environment == "prod"? 1:0 }"
  name            = "${local.environment}-fxmp-int-uk-nlb"
  internal        = false
  enable_cross_zone_load_balancing = true
  load_balancer_type = "network"
  access_logs {
    bucket  = "logging-${local.account_alias_core[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  subnet_mapping {
    subnet_id     = "${element(data.aws_subnet_ids.public_subnets.ids,0)}"
    allocation_id = "${data.aws_eip.fxmp-int-uk.0.id}"
  }
  subnet_mapping {
    subnet_id     = "${element(data.aws_subnet_ids.public_subnets.ids,1)}"
    allocation_id = "${data.aws_eip.fxmp-int-uk.1.id}"
  }
  subnet_mapping {
    subnet_id     = "${element(data.aws_subnet_ids.public_subnets.ids,2)}"
    allocation_id = "${data.aws_eip.fxmp-int-uk.2.id}"
  }
  tags = "${merge(local.default_tags, local.fxmp_tags, map(
    "Name", "${local.environment}-fxmp-int-uk-nlb"
  ))}"
}

resource "aws_lb_target_group" "tg-fxmp-int-uk" {
  count = "${ local.environment == "prod"? 1:0 }"
  name = "${local.environment}-fxmp-int-uk-tg"
  target_type = "instance"
  port = 9603
  protocol = "TCP"
  vpc_id = "${data.aws_vpc.core.id}"
  health_check {
    interval = 10
    healthy_threshold = 3
    port = "traffic-port"
    protocol = "TCP"
  }
}

resource "aws_lb_target_group_attachment" "attach-fxmp-int-uk" {
  count = "${ local.environment == "prod"? data.consul_keys.apigw.var.instance_count:0 }"
  target_group_arn = "${aws_lb_target_group.tg-fxmp-int-uk.arn}"
  target_id        = "${element(aws_instance.apigw.*.id, count.index)}"
  port             = 9603
}

resource "aws_lb_listener" "listener-fxmp-int-uk-https" {
  count = "${ local.environment == "prod"? 1:0 }"
  load_balancer_arn = "${aws_lb.nlb-fxmp-int-uk.arn}"
  port              = "443"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.tg-fxmp-int-uk.arn}"
    type             = "forward"
  }
}

