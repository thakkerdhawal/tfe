#
# Add any extra keys you require in this section
#
data "consul_keys" "bondsyndicate" {
  key {
    name = "bondsyndicate_cert.arn"
    path = "${local.consul_key_inputprefix}/${local.region}/bondsyndicate_cert.arn"
    default = ""
  }
  key {
    name = "public_alb_allowed_cidrs"
    path = "${local.consul_key_inputprefix}/common/public_alb_allowed_cidrs"
    default = ""
  }
  key {
    name = "waf_ruleset_group"
    path = "${local.consul_key_inputprefix}/${local.region}/waf_ruleset_group"
    default = ""
  }
}

