# NLB for Stream Management Traffic - one for each Liberator
#
# An NLB is used to make cert management easier. The cert that is used will be the
# self signed one hosted on each liberator. Real certificates can't be used as there 
# is no internal DNS propagation between campus network and AWS for NWM.
resource "aws_lb" "nlb-stream-mgmt" {
  count           = 3
  name            = "${local.environment}-stream-mgmt-${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}-nlb"
  internal        = true
  enable_cross_zone_load_balancing = true
  load_balancer_type = "network"
  access_logs {
    bucket  = "logging-${local.account_alias_shared-services[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  subnets = ["${module.vpcss.intra_subnets}"]
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-stream-mgmt-${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}-nlb"
  ))}"
}

resource "aws_lb_target_group" "tg-stream-mgmt" {
  count = 3
  name = "${local.environment}-stream-mgmt-${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}-tg"
  target_type = "ip"
  port = 4447
  protocol = "TCP"
  vpc_id = "${module.vpcss.vpc_id}"
  health_check {
    interval = 30
    healthy_threshold = 3
    port = "traffic-port"
    protocol = "HTTPS"
    path = "/"
  }
}

resource "aws_lb_listener" "listener-stream-mgmt-https" {
  count             = 3
  load_balancer_arn = "${element(aws_lb.nlb-stream-mgmt.*.arn, count.index)}"
  port              = "443"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${element(aws_lb_target_group.tg-stream-mgmt.*.arn, count.index)}"
    type             = "forward"
  }
}

# Create NLBs for nonprod Core if this is Prod SS
resource "aws_lb" "nlb-stream-mgmt-nonprod" {
  count           = "${ local.environment == "prod" ? 3: 0 }"
  name            = "nonprod-stream-mgmt-${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}-nlb"
  internal        = true
  enable_cross_zone_load_balancing = true
  load_balancer_type = "network"
  access_logs {
    bucket  = "logging-${local.account_alias_core["nonprod"]}-elblog-${local.region}"
    enabled = true
  }
  subnets = ["${module.vpcss.intra_subnets}"]
  tags = "${merge(local.default_tags, map(
    "Name", "nonprod-stream-mgmt-${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}-nlb"
  ))}"
}

resource "aws_lb_target_group" "tg-stream-mgmt-nonprod" {
  count = "${ local.environment == "prod" ? 3: 0 }"
  name = "nonprod-stream-mgmt-${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}-tg"
  target_type = "ip"
  port = 4447
  protocol = "TCP"
  vpc_id = "${module.vpcss.vpc_id}"
  health_check {
    interval = 30
    healthy_threshold = 3
    port = "traffic-port"
    protocol = "HTTPS"
    path = "/"
  }
}

resource "aws_lb_listener" "listener-stream-mgmt-https-nonprod" {
  count             = "${ local.environment == "prod" ? 3: 0 }"
  load_balancer_arn = "${element(aws_lb.nlb-stream-mgmt-nonprod.*.arn, count.index)}"
  port              = "443"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${element(aws_lb_target_group.tg-stream-mgmt-nonprod.*.arn, count.index)}"
    type             = "forward"
  }
}

