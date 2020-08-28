data "consul_keys" "v" {
  # Currently Common: Same in both regions
  key {
    name = "vlproxy_ingress_instance_type"
    path = "${local.consul_key_inputprefix}/common/vlproxy_ingress_instance_type"
    default = ""
  }
  key {
    name = "vlproxy_root_volume_size"
    path = "${local.consul_key_inputprefix}/common/vlproxy_root_volume_size"
    default = ""
  }
  key {
    name = "vlproxy_harmony_ips"
    path = "${local.consul_key_inputprefix}/common/vlproxy_harmony_ips"
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
}
