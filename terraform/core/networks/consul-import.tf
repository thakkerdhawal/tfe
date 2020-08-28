#
# Define variables from other workspaces
#
data "consul_keys" "import" {
  ## Common
  key {
    name = "req_account_id"
    path = "application/nwm/${element(split("-",data.consul_keys.v.var.peervpc_name),0)}/terraform/shared-services/outputs/networks/${local.region}/account_id"
    default = ""
  }
  key {
    name = "req_vpc_id"
    path = "application/nwm/${element(split("-",data.consul_keys.v.var.peervpc_name),0)}/terraform/shared-services/outputs/networks/${local.region}/vpc_id"
    default = ""
  }
  key {
    name = "req_vpc_cidr_block"
    path = "application/nwm/${element(split("-",data.consul_keys.v.var.peervpc_name),0)}/terraform/shared-services/outputs/networks/${local.region}/vpc_cidr_block"
    default = ""
  }
  key {
    name = "intra_subnets"
    path = "application/nwm/${element(split("-",data.consul_keys.v.var.peervpc_name),0)}/terraform/shared-services/outputs/networks/${local.region}/intra_subnets"
    default = ""
  }
  key {
    name = "bastion_hosts_sg_id"
    path = "application/nwm/${element(split("-",data.consul_keys.v.var.peervpc_name),0)}/terraform/shared-services/outputs/networks/${local.region}/bastion_hosts_sg_id"
    default = ""
  }
  key {
    name = "dx_gw_id"
    path = "application/nwm/${local.environment}/terraform/core/outputs/setup-dcg/eu-west-2/dx_gw_id"
    default = ""
  }
}
