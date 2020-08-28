#### Consul Output ####
resource "consul_key_prefix" "consul_output" {
  path_prefix = "${local.consul_key_outputprefix}/"
  subkeys {
    "vpc_id" = "${(module.vpcnwm.vpc_id)}"
    "vpc_cidr_block" = "${module.vpcnwm.vpc_cidr_block}"
    "vpc_main_route_table_id" ="${(module.vpcnwm.vpc_main_route_table_id)}"
    "vpc_secondary_cidr_blocks"="${join(",",module.vpcnwm.vpc_secondary_cidr_blocks)}"
    "private_subnets" ="${join(",",module.vpcnwm.private_subnets)}"
    "private_subnets_cidr_blocks" = "${join(",",module.vpcnwm.private_subnets_cidr_blocks)}"
    "public_subnets"="${join(",",module.vpcnwm.public_subnets)}"
    "public_subnets_cidr_blocks"="${join(",",module.vpcnwm.public_subnets_cidr_blocks)}"
    "intra_subnets"="${join(",",module.vpcnwm.intra_subnets)}"
    "intra_subnets_cidr_blocks"="${join(",",module.vpcnwm.intra_subnets_cidr_blocks)}"
    "public_route_table_ids"="${join(",",module.vpcnwm.public_route_table_ids)}"
    "private_route_table_ids"="${join(",",module.vpcnwm.private_route_table_ids)}"
    "database_route_table_ids"="${join(",",module.vpcnwm.database_route_table_ids)}"
    "intra_route_table_ids"="${join(",",module.vpcnwm.intra_route_table_ids)}"
    "nat_ids"="${join(",",module.vpcnwm.nat_ids)}"
    "nat_public_ips" ="${join(",",module.vpcnwm.nat_public_ips)}"
    "natgw_ids" ="${join(",",module.vpcnwm.natgw_ids)}"
    "igw_id" ="${(module.vpcnwm.igw_id)}"
    "vpc_endpoint_s3_id" = "${(module.vpcnwm.vpc_endpoint_s3_id)}"
    "vpc_endpoint_s3_pl_id" ="${(module.vpcnwm.vpc_endpoint_s3_pl_id)}"
    "all_hosts_sg_id" = "${aws_security_group.all-hosts-sg.id}"
  }
}

#### Terraform Output ####
output "vpc_id" {
  description = "The ID of the NWM VPC"
  value       = "${(module.vpcnwm.vpc_id)}"
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = "${(module.vpcnwm.vpc_cidr_block)}"
}
