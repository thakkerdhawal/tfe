#### Consul Output ####
resource "consul_key_prefix" "consul_output" {
  path_prefix = "${local.consul_key_outputprefix}/"
  subkeys {
    "glue_zone_name_servers_agilemarkets" = "${join(",",flatten(aws_route53_zone.public_glue_zone_agilemarkets.*.name_servers))}"
    "glue_zone_name_servers_natwestmarkets" = "${join(",",flatten(aws_route53_zone.public_glue_zone_natwestmarkets.*.name_servers))}"
  }
}

#### Terraform Output ####
output "glue_zone_name_servers_agilemarkets" {
  value = ["${aws_route53_zone.public_glue_zone_agilemarkets.*.name_servers}"]
}

output "glue_zone_name_servers_natwestmarkets" {
  value = ["${aws_route53_zone.public_glue_zone_natwestmarkets.*.name_servers}"]
}
