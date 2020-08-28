#### Consul Output ####
resource "consul_key_prefix" "consul_output" {
  path_prefix = "${local.consul_key_outputprefix}/"
  subkeys {
    "dx_gw_id" = "${join(",",aws_dx_gateway.dx_gw.*.id)}"
  }

} 
