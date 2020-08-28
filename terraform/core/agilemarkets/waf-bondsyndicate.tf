#
# Bondsyndicate Regional WAF (ALB)
#

# ALB WAF (Regional)
resource "aws_wafregional_web_acl" "protected_web_acl_bondsyndicate" {
  name = "${local.environment}-bs-protected_web_acl"
  metric_name = "${local.environment}BSProtectedWebACL"
  default_action {
    type = "ALLOW"
  }

  rule {
    override_action {
       type = "NONE"
    }
    priority = 10
    rule_id  = "${data.consul_keys.bondsyndicate.var.waf_ruleset_group}"
    type     = "GROUP"
  }

  logging_configuration {
    log_destination = "${aws_kinesis_firehose_delivery_stream.kinesis-firehose-waf-regional-logs.arn}"
  }
  # This depends on is only here so that all waf_acl's don't create at the same time.
  # Seems there is a lock with setting up the Logging that will cause one of them to fail if creating simultaneously
  depends_on = ["aws_wafregional_web_acl.protected_alb_web_acl_agilemarkets"]
}

resource "aws_wafregional_web_acl_association" "alb-bondsyndicate-waf-assoc" {
  resource_arn = "${aws_lb.alb-bondsyndicate.arn}"
  web_acl_id = "${aws_wafregional_web_acl.protected_web_acl_bondsyndicate.id}"
}

