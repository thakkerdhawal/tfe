#
# Add any extra keys you require in this section
#
data "consul_keys" "currencypay" {
  key {
    name = "currencypay_cert.arn"
    path = "${local.consul_key_inputprefix}/${local.region}/currencypay_cert.arn"
    default = ""
  }
}
