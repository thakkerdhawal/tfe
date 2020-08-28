#
# Empty WAF WebACL that will only be used by the AWS Shield Advanced Response team to add 
# emergency ACLs as required. 
#
resource "aws_wafregional_web_acl" "empty_shield_alb_web_acl_stream" {
  name = "${local.environment}-stream-empty_shield_web_acl"
  metric_name = "${local.environment}StreamEmptyShieldWebACL"
  default_action {
    type = "ALLOW"
  }
  logging_configuration {
    log_destination = "${aws_kinesis_firehose_delivery_stream.kinesis-firehose-waf-regional-logs.arn}"
  }
  # This depends on is only here so that all waf_acl's don't create at the same time.
  # Seems there is a lock with setting up the Logging that will cause one of them to fail if creating simultaneously
  depends_on = ["aws_wafregional_web_acl.protected_web_acl_bondsyndicate"]
}

resource "aws_wafregional_web_acl_association" "alb-stream-waf-assoc" {
  count        = "${data.consul_keys.stream.var.stream_instance_count}"
  resource_arn = "${element(aws_lb.alb-stream-agilemarkets.*.arn, count.index)}"
  web_acl_id   = "${aws_wafregional_web_acl.empty_shield_alb_web_acl_stream.id}"
}

