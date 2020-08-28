#
# Add any extra keys you require in this section
#
data "consul_keys" "cnf" {
  key {
    name = "connectionid"
    path = "${local.consul_key_inputprefix}/${local.region}/dx_connectionid"
    default = ""
  }
  key {
    name = "vlan"
    path = "${local.consul_key_inputprefix}/${local.region}/dx_vlan"
    default = ""
  }
  key {
    name = "amazonaddress"
    path = "${local.consul_key_inputprefix}/${local.region}/dx_amazonaddress"
    default = ""
  }
  key {
    name = "customeraddress"
    path = "${local.consul_key_inputprefix}/${local.region}/dx_customeraddress"
    default = ""
  }
  key {
    name = "authkey"
    path = "${local.consul_key_inputprefix}/common/dx_authkey"
    default = ""
  }
  key {
    name = "aws_asn"
    path = "${local.consul_key_inputprefix}/common/dx_aws_asn"
    default = ""
  }
  key {
    name = "bgp_asn"
    path = "${local.consul_key_inputprefix}/common/dx_bgp_asn"
    default = ""
  }

}
