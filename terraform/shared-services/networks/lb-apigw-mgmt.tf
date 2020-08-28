# NLB for API Gateway Management Traffic - one for each Gateway
resource "aws_lb" "nlb-apigw-mgmt" {
  count         = 2
  name            = "${local.environment}-apigw-mgmt-${count.index + 1}-nlb"
  internal        = true
  enable_cross_zone_load_balancing = true
  load_balancer_type = "network"
  access_logs {
    bucket  = "logging-${local.account_alias_shared-services[local.environment]}-elblog-${local.region}"
    enabled = true
  }
  subnets = ["${module.vpcss.intra_subnets}"]
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-apigw-mgmt-${count.index + 1}-nlb"
  ))}"
}

resource "aws_lb_target_group" "tg-apigw-mgmt" {
  count         = 2
  name = "${local.environment}-apigw-mgmt-${count.index + 1}-tg"
  target_type = "ip"
  port = 8443
  protocol = "TCP"
  vpc_id = "${module.vpcss.vpc_id}"
  health_check {
    interval = 30
    healthy_threshold = 3
    port = "traffic-port"
    protocol = "HTTPS"
    path = "/ssg/ping"
  }
}

resource "aws_lb_listener" "listener-apgw-mgmt-https" {
  count         = 2
  load_balancer_arn = "${element(aws_lb.nlb-apigw-mgmt.*.arn, count.index)}"
  port              = "443"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${element(aws_lb_target_group.tg-apigw-mgmt.*.arn, count.index)}"
    type             = "forward"
  }
}

# Create NLBs for nonprod Core if this is Prod SS
resource "aws_lb" "nlb-apigw-mgmt-nonprod" {
  count         = "${ local.environment == "prod" ? 2: 0 }"
  name            = "nonprod-apigw-mgmt-${count.index + 1}-nlb"
  internal        = true
  enable_cross_zone_load_balancing = true
  load_balancer_type = "network"
  access_logs {
    bucket  = "logging-${local.account_alias_core["nonprod"]}-elblog-${local.region}"
    enabled = true
  }
  subnets = ["${module.vpcss.intra_subnets}"]
  tags = "${merge(local.default_tags, map(
    "Name", "nonprod-apigw-mgmt-${count.index + 1}-nlb"
  ))}"
}

resource "aws_lb_target_group" "tg-apigw-mgmt-nonprod" {
  count         = "${ local.environment == "prod" ? 2: 0 }"
  name = "nonprod-apigw-mgmt-${count.index + 1}-tg"
  target_type = "ip"
  port = 8443
  protocol = "TCP"
  vpc_id = "${module.vpcss.vpc_id}"
  health_check {
    interval = 30
    healthy_threshold = 3
    port = "traffic-port"
    protocol = "HTTPS"
    path = "/ssg/ping"
  }
}

resource "aws_lb_listener" "listener-apgw-mgmt-https-nonprod" {
  count         = "${ local.environment == "prod" ? 2: 0 }"
  load_balancer_arn = "${element(aws_lb.nlb-apigw-mgmt-nonprod.*.arn, count.index)}"
  port              = "443"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${element(aws_lb_target_group.tg-apigw-mgmt-nonprod.*.arn, count.index)}"
    type             = "forward"
  }
}

