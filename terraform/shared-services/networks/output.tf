#### Consul Output ####
resource "consul_key_prefix" "consul_output" {
  path_prefix = "${local.consul_key_outputprefix}/"
  subkeys {
    "account_id" = "${data.aws_caller_identity.current.account_id}"
    "vpc_id" = "${(module.vpcss.vpc_id)}"
    "vpc_cidr_block" = "${module.vpcss.vpc_cidr_block}"
    "vpc_main_route_table_id" ="${(module.vpcss.vpc_main_route_table_id)}"
    "vpc_secondary_cidr_blocks"="${join(",",module.vpcss.vpc_secondary_cidr_blocks)}"
    "private_subnets" ="${join(",",module.vpcss.private_subnets)}"
    "private_subnets_cidr_blocks" = "${join(",",module.vpcss.private_subnets_cidr_blocks)}"
    "public_subnets"="${join(",",module.vpcss.public_subnets)}"
    "public_subnets_cidr_blocks"="${join(",",module.vpcss.public_subnets_cidr_blocks)}"
    "intra_subnets"="${join(",",module.vpcss.intra_subnets)}"
    "intra_subnets_cidr_blocks"="${join(",",module.vpcss.intra_subnets_cidr_blocks)}"
    "public_route_table_ids"="${join(",",module.vpcss.public_route_table_ids)}"
    "private_route_table_ids"="${join(",",module.vpcss.private_route_table_ids)}"
    "database_route_table_ids"="${join(",",module.vpcss.database_route_table_ids)}"
    "intra_route_table_ids"="${join(",",module.vpcss.intra_route_table_ids)}"
    "nat_ids"="${join(",",module.vpcss.nat_ids)}"
    "nat_public_ips" ="${join(",",module.vpcss.nat_public_ips)}"
    "natgw_ids" ="${join(",",module.vpcss.natgw_ids)}"
    "igw_id" ="${(module.vpcss.igw_id)}"
    "vpc_endpoint_s3_id" = "${(module.vpcss.vpc_endpoint_s3_id)}"
    "vpc_endpoint_s3_pl_id" ="${(module.vpcss.vpc_endpoint_s3_pl_id)}"
    "all_hosts_sg_id" = "${aws_security_group.all-hosts-sg.id}"
    "bastion_hosts_sg_id" = "${aws_security_group.bastion-hosts-sg.id}"
    "netcool_lambda_arn"  = "${join(",",aws_lambda_function.netcool-lambda.*.arn)}"
    "apigw_mgmt_nlb" = "${join(",",aws_lb.nlb-apigw-mgmt.*.dns_name)}"
    "apigw_mgmt_nlb_nonprod" = "${join(",",aws_lb.nlb-apigw-mgmt-nonprod.*.dns_name)}"
    "stream_mgmt_nlb" = "${join(",",aws_lb.nlb-stream-mgmt.*.dns_name)}"
    "stream_mgmt_nlb_nonprod" = "${join(",",aws_lb.nlb-stream-mgmt-nonprod.*.dns_name)}"
  }
}

#### Terraform Output ####
output "vpc_id" {
  description = "The ID of the NWM VPC"
  value       = "${(module.vpcss.vpc_id)}"
}

output "vpc_cidr_block" {
description = "The CIDR block of the VPC"
value       = "${(module.vpcss.vpc_cidr_block)}"
}

output "netcool_lambda_arn" {
  description = "ARN for the Lambda function that will post to netcool"
  value = "${aws_lambda_function.netcool-lambda.*.arn}"
}


