data "aws_route53_zone" "fxmp_www_zone" {
  name         = "${local.environment}.cloud.natwestmarkets.com."
}

data "aws_eip" "fxmp-uk" {
  count = 3
  tags = {
    Name = "${local.environment}-fxmp-${count.index + 1}"
  }
}

data "aws_eip" "fxmp-us" {
  count = 3
  tags = {
    Name = "${local.environment}-fxmp-us-${count.index + 1}"
  }
}

data "aws_eip" "fxmp-int-uk" {
  count = "${ local.environment == "prod"? 3:0 }"
  tags = {
    Name = "${local.environment}-fxmp-int-${count.index + 1}"
  }
}

data "aws_eip" "fxmp-int-us" {
  count = "${ local.environment == "prod"? 3:0 }"
  tags = {
    Name = "${local.environment}-fxmp-int-us-${count.index + 1}"
  }
}

