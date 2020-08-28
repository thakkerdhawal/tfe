#
# Add any extra keys you require in this section
#
data "consul_keys" "v" {
  # Common: same in both regions
  key {
    name = "agilemarket_www_cert.arn"
    path = "${local.consul_key_inputprefix}/${local.region}/agilemarket_www_cert.arn"
    default = ""
  }
  key {
    name = "agilemarkets_dns_external"
    path = "${local.consul_key_inputprefix}/common/agilemarkets_dns_external"
    default = ""
  }
  key {
    name = "des_rhel7_ami_version_filter"
    path = "${local.consul_key_inputprefix}/common/des_rhel7_ami_version_filter"
    default = ""
  }
  key {
    name = "public_alb_allowed_cidrs"
    path = "${local.consul_key_inputprefix}/common/public_alb_allowed_cidrs"
    default = ""
  }
  key {
    name = "rbs_lanproxy_cidrs"
    path = "${local.consul_key_inputprefix}/common/rbs_lanproxy_cidrs"
    default = ""
  }
  key {
    name = "waf_ruleset_group"
    path = "${local.consul_key_inputprefix}/${local.region}/waf_ruleset_group"
    default = ""
  }
  key {
    name = "internal_dnshealthcheck_urls"
    path = "${local.consul_key_inputprefix}/common/internal_dnshealthcheck_urls"
    default = ""
  }
  key {
    name = "peervpc_name"
    path = "${local.consul_key_inputprefix}/${local.region}/peervpc_name"
    default = ""
  }
}
