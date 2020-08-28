#
# Add any extra keys you require in this section
#
data "consul_keys" "netcool" {
  key {
    name = "netcool_ip"
    path = "${local.consul_key_inputprefix}/common/netcool_ip"
    default = ""
  }
}
