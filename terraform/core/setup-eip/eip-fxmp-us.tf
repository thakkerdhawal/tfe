
resource "aws_eip" "fxmp-us-1" {
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-us-1"
  ))}"
}

resource "aws_eip" "fxmp-us-2" {
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-us-2"
  ))}"
}

resource "aws_eip" "fxmp-us-3" {
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-us-3"
  ))}"
}

resource "aws_eip" "fxmp-int-us-1" {
  count = "${ local.environment == "prod" ? 1:0 }"
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-int-us-1"
  ))}"
}

resource "aws_eip" "fxmp-int-us-2" {
  count = "${ local.environment == "prod" ? 1:0 }"
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-int-us-2"
  ))}"
}

resource "aws_eip" "fxmp-int-us-3" {
  count = "${ local.environment == "prod" ? 1:0 }"
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-fxmp-int-us-3"
  ))}"
}
