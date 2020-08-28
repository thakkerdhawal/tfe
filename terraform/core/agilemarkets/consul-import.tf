#
# Define variables from other workspaces
#
data "consul_keys" "import" {
  key {
    name = "bastion_hosts_private_ips"
    path = "application/nwm/${element(split("-",data.consul_keys.v.var.peervpc_name),0)}/terraform/shared-services/outputs/bastion/${local.region}/bastion_hosts_private_ips"
    default = ""
  } 
  key {
    name = "intra_subnets_cidr_blocks"
    path = "application/nwm/${element(split("-",data.consul_keys.v.var.peervpc_name),0)}/terraform/shared-services/outputs/networks/${local.region}/intra_subnets_cidr_blocks"
    default = ""
  }
}
