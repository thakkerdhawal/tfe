resource "aws_cloudwatch_log_metric_filter" "ct-audit-console-privilage-log-filter" {
  name           = "Event-Console-Login-PowerUsers-filter"
  pattern        = "{ $.responseElements.ConsoleLogin = \"Success\" &&  $.userIdentity.arn != \"*ReadOnly*\"  }"
  log_group_name = "${aws_cloudwatch_log_group.ct-audit-lg.name}"

  metric_transformation {
    name      = "EventCount-Console-Login-Privilage"
    namespace = "cloudtrail-audit-loggroup"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ct-audit-console-privilage-log-alarm" {
  count                     = "${local.region == "eu-west-2" ? 1 : 0}"
  alarm_name                = "Audit-Console-Login-privilage-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "EventCount-Console-Login-Privilage"
  namespace                 = "cloudtrail-audit-loggroup"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "0"
  alarm_description         = "This metric monitors console login with PowerUsers or Administrator access"
  insufficient_data_actions = []
  alarm_actions             = ["${data.consul_keys.import.var.netcool_sns_arn}"]
  treat_missing_data        = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "ct-audit-cli-log-filter" {
  name           = "Event-Cli-SAML-filter"
  pattern        = "{ $.eventName = \"AssumeRoleWithSAML\" && $.userAgent = \"aws-sdk*\" && $.requestParameters.roleArn != \"*ReadOnly\" }"
  log_group_name = "${aws_cloudwatch_log_group.ct-audit-lg.name}"

  metric_transformation {
    name      = "EventCount-Cli-SAML-Metric"
    namespace = "cloudtrail-audit-loggroup"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ct-audit-cli-log-alarm" {
  count                     = "${local.region == "eu-west-2" ? 1 : 0}"
  alarm_name                = "Audit-Cli-SAML-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "EventCount-Cli-SAML-Metric"
  namespace                 = "cloudtrail-audit-loggroup"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "0"
  alarm_description         = "This metric monitors cli activity for powerusers"
  insufficient_data_actions = []
  alarm_actions             = ["${data.consul_keys.import.var.netcool_sns_arn}"]
  treat_missing_data        = "notBreaching"
}
