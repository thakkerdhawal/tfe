#
# Add any extra keys you require in this section
#
data "consul_keys" "apigw" {
  # Common: same in both regions
  key {
    name = "instance_count"
    path = "${local.consul_key_inputprefix}/common/apigw_instance_count"
    default = ""
  }
  key {
    name = "instance_type"
    path = "${local.consul_key_inputprefix}/common/apigw_instance_type"
    default = ""
  }
  key {
    name = "backends"
    path = "${local.consul_key_inputprefix}/common/apigw_backends"
    # Format: CIDR:PORT,CIDR:PORT
    default = ""
  }
  key {
    name = "des_apigw_ami_version_filter"
    path = "${local.consul_key_inputprefix}/common/des_apigw_ami_version_filter"
    default = ""
  }
  key {
    name = "rbsagile_bundle"
    path = "${local.consul_key_inputprefix}/common/apigw_rbsagile_bundle"
    default = ""
  }
  key {
    name = "build_package"
    path = "${local.consul_key_inputprefix}/common/apigw_build_package"
    default = ""
  }
  key {
    name = "cwp"
    path = "${local.consul_key_inputprefix}/common/apigw_cwp"
    default = ""
  }
}
