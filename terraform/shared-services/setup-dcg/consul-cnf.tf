#
# Add any extra keys you require in this section
#
data "consul_keys" "cnf" {
  key {
    name = "aws_asn"
    path = "${local.consul_key_inputprefix}/common/dx_aws_asn"
    default = ""
  }
}
