#
# Define variables from other workspaces
#
data "consul_keys" "import" {
  key {
    name = "netcool_sns_arn"
    path = "application/nwm/${element(split("-",data.consul_keys.v.var.peervpc_name),0)}/terraform/shared-services/outputs/setup-audit/${local.region}/netcool_sns_arn"
    default = ""
  }
}
