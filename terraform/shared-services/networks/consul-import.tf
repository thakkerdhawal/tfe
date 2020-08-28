#
# Define variables from other workspaces
#
data "consul_keys" "import" {
  ## Common
  key {
    name = "dx_gw_id"
    path = "application/nwm/${local.environment}/terraform/shared-services/outputs/setup-dcg/eu-west-2/dx_gw_id"
    default = ""
  }
}

