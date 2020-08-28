#
# Glue DNS Zone for NatWestmarkets.com
#
resource "aws_route53_zone" "public_glue_zone_natwestmarkets" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "${local.environment}.cloud.natwestmarkets.com"
  lifecycle {
    prevent_destroy = true
  }
  tags = "${merge(local.default_tags, map(
    "Name", "public-glue-zone-${local.environment}.cloud.natwestmarkets.com"
  ))}"
}

