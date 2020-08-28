#
# Glue DNS Zone for AgileMarkets.com
#
resource "aws_route53_zone" "public_glue_zone_agilemarkets" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name = "${local.environment}.cloud.agilemarkets.com"
  lifecycle {
    prevent_destroy = true
  }
  tags = "${merge(local.default_tags, map(
    "Name", "public-glue-zone-${local.environment}.cloud.agilemarkets.com"
  ))}"
}

