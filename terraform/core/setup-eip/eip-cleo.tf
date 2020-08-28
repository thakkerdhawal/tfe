resource "aws_eip" "cleo" {
  vpc = true
  lifecycle {
    prevent_destroy = true 
  } 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-cleo"
  ))}"
}
