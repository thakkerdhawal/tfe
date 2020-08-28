resource "aws_eip" "fxmp-1" {
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-1"
  ))}"
}

resource "aws_eip" "fxmp-2" {
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-2"
  ))}"
}

resource "aws_eip" "fxmp-3" {
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-3"
  ))}"
}

resource "aws_eip" "fxmp-int-1" {
  count = "${ local.environment == "prod" ? 1:0 }"
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-int-1"
  ))}"
}

resource "aws_eip" "fxmp-int-2" {
  count = "${ local.environment == "prod" ? 1:0 }"
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-int-2"
  ))}"
}

resource "aws_eip" "fxmp-int-3" {
  count = "${ local.environment == "prod" ? 1:0 }"
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-int-3"
  ))}"
}
