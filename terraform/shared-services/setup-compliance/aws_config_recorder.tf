# This is to setup the configuration recorder and role/policy attachement
resource "aws_config_configuration_recorder" "aws_config_recorder" {
  name     = "nwm_aws_config_recorder"
  role_arn = "${data.aws_iam_role.aws_config_role.arn}"

  recording_group {
    all_supported                 = "true"
    include_global_resource_types = "${local.region == "eu-west-2"? "true": "false"}"
  }
}

resource "aws_config_configuration_recorder_status" "aws_config_recorder_status" {
  name       = "${aws_config_configuration_recorder.aws_config_recorder.name}"
  is_enabled = true
  depends_on = ["aws_config_delivery_channel.s3_delivery"]
}

resource "aws_config_delivery_channel" "s3_delivery" {
  name           = "s3_config_bucket"
  s3_bucket_name = "logging-${data.aws_iam_account_alias.current.account_alias}-awsconfig-${local.region}"

  # Enabling the sns_topic_arn delivers every change etc. to that topic
  sns_topic_arn  = "arn:aws:sns:${local.region}:${local.account_number_shared-services[local.ss_environment]}:${local.ss_environment}-netcool-sns-topic"
  depends_on = ["aws_config_configuration_recorder.aws_config_recorder"]
}
