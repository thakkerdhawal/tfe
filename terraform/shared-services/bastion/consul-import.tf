#
# Define variables from other workspaces
#
data "consul_keys" "import" {
  ## Common
  key {
    name = "vpc_id"
    path = "application/nwm/${local.environment}/terraform/shared-services/outputs/networks/${local.region}/vpc_id"
    default = ""
  }
  key {
    name = "intra_subnets"
    path = "application/nwm/${local.environment}/terraform/shared-services/outputs/networks/${local.region}/intra_subnets"
    default = ""
  }
  key {
    name = "all_hosts_sg_id"
    path = "application/nwm/${local.environment}/terraform/shared-services/outputs/networks/${local.region}/all_hosts_sg_id"
    default = ""
  }
  key {
    name = "bastion_hosts_sg_id"
    path = "application/nwm/${local.environment}/terraform/shared-services/outputs/networks/${local.region}/bastion_hosts_sg_id"
    default = ""
  }
}
