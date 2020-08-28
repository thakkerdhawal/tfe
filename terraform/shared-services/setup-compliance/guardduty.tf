resource "aws_guardduty_detector" "guardduty" {
  enable = true
}

resource "aws_guardduty_detector" "guardduty-us-east-1" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  provider    = "aws.us-east-1"

  enable = true
}
