resource "aws_dx_gateway" "dx_gw" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  name = "${local.environment}-dxgw"
  amazon_side_asn = "${data.consul_keys.cnf.var.aws_asn}"
}
