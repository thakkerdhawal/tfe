#
# Add any extra keys you require in this section
#
data "consul_keys" "v" {
   ## Bastion host
   key {
    name = "bastion_instance_count"
    path = "${local.consul_key_inputprefix}/common/bastion_instance_count"
    default = ""
  }
  key {
    name = "bastion_instance_type"
    path = "${local.consul_key_inputprefix}/common/bastion_instance_type"
    default = ""
  }
  key {
    name = "bastion_inbound_ips"
    path = "${local.consul_key_inputprefix}/common/bastion_inbound_cidr"
    default = ""
  }
  key {
    name = "des_rhel7_ami_version_filter"
    path = "${local.consul_key_inputprefix}/common/des_rhel7_ami_version_filter"
    default = ""
  }
}
