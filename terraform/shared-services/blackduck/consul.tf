#
# Add any extra keys you require in this section
#
data "consul_keys" "blackduck" {
  key {
    name = "blackduck_ami"
    path = "${local.consul_key_inputprefix}/${local.region}/blackduck_ami"
    default = ""
  }
  key {
    name = "blackduck_dns"
    path = "${local.consul_key_inputprefix}/common/blackduck_dns"
    default = ""
  }
  key {
    name = "blackduck_rds_instance_type"
    path = "${local.consul_key_inputprefix}/common/blackduck_rds_instance_type"
    default = ""
  }
  key {
    name = "blackduck_instance_type"
    path = "${local.consul_key_inputprefix}/common/blackduck_instance_type"
    default = ""
  }
  key {
    name = "blackduck_rootsize"
    path = "${local.consul_key_inputprefix}/common/blackduck_rootsize"
    default = ""
  }
  key {
    name = "blackduck_cert_arn"
    path = "${local.consul_key_inputprefix}/${local.region}/blackduck_cert_arn"
    default = ""
  }
  key {
    name = "blackduck_internal_cert_arn"
    path = "${local.consul_key_inputprefix}/${local.region}/blackduck_internal_cert_arn"
    default = ""
  }
  key {
    name = "blackduck_public_allowed_cidrs"
    path = "${local.consul_key_inputprefix}/common/blackduck_public_allowed_cidrs"
    default = ""
  }
    key {
    name = "rbs_lanproxy_cidrs"
    path = "${local.consul_key_inputprefix}/common/rbs_lanproxy_cidrs"
    default = ""
  }
  key {
    name = "dns_zone"
    path = "${local.consul_key_inputprefix}/common/dns_zone"
    default = ""
  }
}
