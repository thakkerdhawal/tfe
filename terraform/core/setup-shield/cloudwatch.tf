
resource "aws_cloudwatch_metric_alarm" "shield_ddos_alarm" {
  alarm_name                = "DDosDetectedAlarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = "1"
  evaluation_periods        = "20"
  period                    = "60"
  namespace                 = "AWS/DDoSProtection"
  metric_name               = "DDoSDetected"
  statistic                 = "Sum"
  alarm_description         = "This metric monitors DDoS alerts from AWS Shield Advanced for protected resources"
  treat_missing_data        = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "shield_ddos_alarm_global" {
  count                     = "${local.region == "eu-west-2" ? 1 : 0}"
  provider                  = "aws.us-east-1"
  alarm_name                = "DDosDetectedAlarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = "1"
  evaluation_periods        = "20"
  period                    = "60"
  namespace                 = "AWS/DDoSProtection"
  metric_name               = "DDoSDetected"
  statistic                 = "Sum"
  alarm_description         = "This metric monitors DDoS alerts from AWS Shield Advanced for protected resources"
  treat_missing_data        = "notBreaching"
}

