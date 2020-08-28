#
# Add any extra keys you require in this section
#
data "consul_keys" "v" {
  key {
    name = "peervpc_name"
    path = "${local.consul_key_inputprefix}/${local.region}/peervpc_name"
    default = ""
  }
}
