# Creator's side of the VIF
resource "aws_dx_private_virtual_interface" "dxvi" {
  # this can be found in AWS Console
  count              = "${length(split(",",data.consul_keys.cnf.var.connectionid))}"
  connection_id      = "${element(split(",",data.consul_keys.cnf.var.connectionid),count.index)}"
  name               = "${local.account}-${local.environment}-cnf"
  # this can be found in AWS Console
  vlan               = "${element(split(",",data.consul_keys.cnf.var.vlan),count.index)}"
  address_family     = "ipv4"
  bgp_asn            = "${element(split(",",data.consul_keys.cnf.var.bgp_asn),count.index)}"
  amazon_address     = "${element(split(",",data.consul_keys.cnf.var.amazonaddress),count.index)}"
  customer_address   = "${element(split(",",data.consul_keys.cnf.var.customeraddress),count.index)}"
  bgp_auth_key       = "${data.consul_keys.cnf.var.authkey}"
  dx_gateway_id      = "${data.consul_keys.import.var.dx_gw_id}"
}

resource "aws_vpn_gateway" "vpn_gw" {
  amazon_side_asn = "${data.consul_keys.cnf.var.aws_asn}"
  tags = "${merge(local.default_tags, map(
    "Name", "${local.account}-${local.environment}-vpg"
  ))}"
}

resource "aws_dx_gateway_association" "dx_gw_association" {
  dx_gateway_id =  "${data.consul_keys.import.var.dx_gw_id}"
  vpn_gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
  depends_on = ["aws_vpn_gateway.vpn_gw","aws_vpn_gateway_attachment.vpgss_attachment"]
  timeouts {
   create = "15m"
   delete = "15m"
  }
}
