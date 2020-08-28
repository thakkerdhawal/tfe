# 
# The main NLB for Ingress Traffic for Cleo VLProxy
# Initially the requirement is port 22 only (sftp) that will talk to port 9022 on the VLProxy servers
# Port 9022 doesn't get enabled on the vlproxy servers until the vlproxy instance has been configured by Cleo Harmony
# Port 8080 is enabled however and the daemon listens on that for connections from Cleo Harmony.
#

# Define NLB: nlb-vlproxy-ingress

resource "aws_lb" "nlb-vlproxy-ingress" {
  name = "${local.environment}-vlproxy-ingress-nlb"
  load_balancer_type = "network"
  internal = false
  access_logs {
    bucket  = "logging-${local.account_alias_core[local.environment]}-elblog-${local.region}"
    enabled = true
  }
# subnets = ["${data.aws_subnet_ids.public_subnets.ids}"]
  subnet_mapping {
    subnet_id     = "${data.aws_subnet.vlproxyPublicSubnet.id}"
    allocation_id = "${data.aws_eip.vlproxy.id}"
  }
   tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-vlproxy-ingress-nlb"
  ))}"
}

resource "aws_lb_listener" "listener-vlproxy-ingress-sftp" {
  load_balancer_arn = "${aws_lb.nlb-vlproxy-ingress.arn}"
  port              = "22"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.tg-vlproxy-ingress.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "tg-vlproxy-ingress" {
  name = "${local.environment}-vlproxy-ingress-tg"
  target_type = "instance"
  port = 9022
  protocol = "TCP"
  vpc_id = "${data.aws_vpc.core.id}"
  health_check {
    interval = 30
    healthy_threshold = 3
    port = "traffic-port"
    protocol = "TCP"
  }
}

resource "aws_lb_target_group_attachment" "attach-vlproxy-ingress" {
  count         = "1"
  target_group_arn = "${aws_lb_target_group.tg-vlproxy-ingress.arn}"
  target_id        = "${element(aws_instance.vlproxy-ingress.*.id, count.index)}"
  port             = 9022
}



# Define NLB: nlb-vlproxy-monitor

resource "aws_lb" "nlb-vlproxy-monitor" {
  name = "${local.environment}-vlproxy-monitor-8080-nlb"
  count = "1"
  load_balancer_type = "network"
  internal = true
  subnets = ["${element(data.aws_subnet_ids.intra_subnets.ids, count.index)}"]

   tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-vlproxy-monitor-8080-nlb"
  ))}"
}

resource "aws_lb_listener" "listener-vlproxy-monitor" {
  load_balancer_arn = "${aws_lb.nlb-vlproxy-monitor.arn}"
  port              = "8080"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.tg-vlproxy-monitor.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "tg-vlproxy-monitor" {
  name = "${local.environment}-vlproxy-monitor-tg"
  target_type = "instance"
  port = 8080
  protocol = "TCP"
  vpc_id = "${data.aws_vpc.core.id}"
  health_check {
    interval = 10
    healthy_threshold = 3
    port = "traffic-port"
    protocol = "TCP"
  }
}

resource "aws_lb_target_group_attachment" "attach-vlproxy-monitor" {
  count         = "1"
  target_group_arn = "${aws_lb_target_group.tg-vlproxy-monitor.arn}"
  target_id        = "${element(aws_instance.vlproxy-ingress.*.id, count.index)}"
  port             = 8080
}
