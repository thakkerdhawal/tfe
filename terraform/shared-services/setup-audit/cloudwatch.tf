# sample cloudwatch example with required format

resource "aws_cloudwatch_metric_alarm" "netcool-instance-metric-alarm8" {
  alarm_name                = "${replace(local.component, "-", "_")}-${local.environment}-i-123345555-ec2-cpu-high-cwalarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Sum"
  threshold                 = "0.1"
  alarm_description         = "This metric for instance alarm" 
  insufficient_data_actions = []
  alarm_actions             = ["${aws_sns_topic.netcool-sns.arn}"]
}


resource "aws_cloudwatch_metric_alarm" "netcool-instance-metric-alarm9" {
  alarm_name                = "${replace("DES-Prod-CCT-eCommerce", "-", "_")}-${replace(local.component, "-", "_")}-${local.environment}-i-123345556-ec2-cpu-high-cwalarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Sum"
  threshold                 = "0.1"
  alarm_description         = "This metric for instance alarm" 
  insufficient_data_actions = []
  alarm_actions             = ["${aws_sns_topic.netcool-sns.arn}"]
}
