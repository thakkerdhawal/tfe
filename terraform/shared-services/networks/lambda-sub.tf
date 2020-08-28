
resource "aws_sns_topic_subscription" "netcool-sns-lambda-sub" {
  topic_arn = "${data.aws_sns_topic.netcool-sns.arn}"
  protocol  = "lambda"
  endpoint = "${aws_lambda_function.netcool-lambda.arn}"
}
