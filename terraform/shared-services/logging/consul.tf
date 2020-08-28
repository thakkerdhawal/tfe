#
# Add any extra keys you require in this section
#
data "consul_keys" "v" {
  key {
    name = "des_rhel7_ami_version_filter"
    path = "${local.consul_key_inputprefix}/common/des_rhel7_ami_version_filter"
    default = ""
  }
  key {
    name = "rbs_lanproxy_cidrs"
    path = "${local.consul_key_inputprefix}/common/rbs_lanproxy_cidrs"
    default = ""
  }
  key {
    name = "logging_instance_type"
    path = "${local.consul_key_inputprefix}/common/logging_instance_type"
    default = ""
  }
  key {
    name = "logging_cert_domain"
    path = "${local.consul_key_inputprefix}/common/logging_cert_domain"
    default = ""
  }
}
