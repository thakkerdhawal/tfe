#
# Add any extra keys you require in this section
#
data "consul_keys" "v" {
  ## Common
  key {
    name = "bu"
    path = "${local.consul_key_inputprefix}/common/bu"
    default = ""
  }
  key {
    name = "owner"
    path = "${local.consul_key_inputprefix}/common/owner"
    default = ""
  }
  key {
    name = "costcenter"
    path = "${local.consul_key_inputprefix}/common/costcenter"
    default = ""
  }
  key {
    name = "bastion_inbound_ips"
    path = "${local.consul_key_inputprefix}/common/bastion_inbound_cidr"
    default = ""
  }
  ## CTO peering 
   key {
    name = "cto_subnet"
    path = "${local.consul_key_inputprefix}/common/cto_subnet"
    default = ""
  }
  ## Region specific
  key {
    name = "private_subnets"
    path = "${local.consul_key_inputprefix}/${local.region}/private_subnets"
    default = ""
  }
  key {
    name = "public_subnets"
    path = "${local.consul_key_inputprefix}/${local.region}/public_subnets"
    default = ""
  }
  key {
    name = "vpc_cidr"
    path = "${local.consul_key_inputprefix}/${local.region}/vpc_cidr"
    default = ""
  }
  key {
    name = "az_number"
    path = "${local.consul_key_inputprefix}/${local.region}/az_number"
    default = ""
  }
  key {
    name = "peervpc_name"
    path = "${local.consul_key_inputprefix}/${local.region}/peervpc_name"
    default = ""
  }
  key {
    name = "intra_subnets"
    path = "${local.consul_key_inputprefix}/${local.region}/intra_subnets"
    default = ""
  }
 }
