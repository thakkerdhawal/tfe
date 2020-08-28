#
# WAF WebACL that is attached to the main Web ALB.
#

# ALB WAF (Regional)
resource "aws_wafregional_web_acl" "protected_alb_web_acl_agilemarkets" {
  name = "${local.environment}-am_protected_web_acl"
  metric_name = "${local.environment}AMProtectedWebACL"
  default_action {
    type = "ALLOW"
  }

  rule {
    override_action {
       type = "NONE"
    }
    priority = 10
    rule_id  = "${data.consul_keys.v.var.waf_ruleset_group}"
    type     = "GROUP"
  }

  logging_configuration {
    log_destination = "${aws_kinesis_firehose_delivery_stream.kinesis-firehose-waf-regional-logs.arn}"
  }
}

resource "aws_wafregional_web_acl_association" "alb-agilemarkets-waf-assoc" {
  resource_arn = "${aws_lb.alb-agilemarkets.arn}"
  web_acl_id = "${aws_wafregional_web_acl.protected_alb_web_acl_agilemarkets.id}"
}

