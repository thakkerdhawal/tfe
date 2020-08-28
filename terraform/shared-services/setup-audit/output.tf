#### Consul Output ####
resource "consul_key_prefix" "consul_output" {
  path_prefix = "${local.consul_key_outputprefix}/"
  subkeys {
    "netcool_sns_arn" = "${aws_sns_topic.netcool-sns.arn}"
    "netcool_sns_id" = "${aws_sns_topic.netcool-sns.id}"
  }
}

output "netcool_sns_arn" {
  description = "ARN for the SNS topic used to post to netcool via lambda"
  value = "${aws_sns_topic.netcool-sns.arn}"
}

output "netcool_sns_id" {
  description = "ID for the SNS topic used to post to netcool via lambda"
  value = "${aws_sns_topic.netcool-sns.id}"
}
