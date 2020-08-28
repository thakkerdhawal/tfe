##
## Configure Peering with the shared services accounts VPC and setup routing
##

#
## Request Peering
resource "aws_vpc_peering_connection" "requester-ctoss-vpc" {
  provider      = "aws.ctovpcpeer"
  peer_owner_id = "${data.aws_caller_identity.current.account_id}"
  peer_vpc_id   = "${module.vpcss.vpc_id}"
  vpc_id        = "vpc-001d7a501f7341bfb"
  # TODO: cater for cross region
  peer_region  = "${local.region}"
  auto_accept   = false
}

# Accept Peering from the NWM shared services account
resource "aws_vpc_peering_connection_accepter" "accepter-ss-vpc" {
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester-ctoss-vpc.id}"
  auto_accept               = true
}

# Route from the private subnets in Shared VPC to private subnet in CTO  VPC
resource "aws_route" "ssvpc-private-to-ctossvpc" {
  # count 		    = "${length(split(",",data.consul_keys.v.var.private_subnets))}"
  count = 1
  route_table_id 	    = "${element(module.vpcss.private_route_table_ids, count.index)}"
  destination_cidr_block    = "${data.consul_keys.v.var.cto_subnet}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester-ctoss-vpc.id}"
}

# Route from the public subnets in Shared VPC to CTO VPC 
resource "aws_route" "ssvpc-public-to-ctossvpc" {
  count = 1
  route_table_id 	    = "${element(module.vpcss.public_route_table_ids, count.index)}"
  destination_cidr_block    = "${data.consul_keys.v.var.cto_subnet}" 
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester-ctoss-vpc.id}"
}

# Route from the intra subnets in Shared VPC to CTO VPC 
resource "aws_route" "ssvpc-intra-to-ctossvpc" {
  count = 1
  route_table_id 	    = "${element(module.vpcss.intra_route_table_ids, count.index)}"
  destination_cidr_block    = "${data.consul_keys.v.var.cto_subnet}"  
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester-ctoss-vpc.id}"
}

#Had to comment out until they get their lambda function sorted 
#Create a route in the route table on the requester (CTO) side
data "aws_lambda_invocation" "create_route_table_entry" {
  provider      = "aws.ctovpcpeer"
  function_name = "create_route_table_entry"

  input = <<JSON
{
  "table_Id": "rtb-0bc6c65d9bfa8b932",
  "peering_Id": "${aws_vpc_peering_connection.requester-ctoss-vpc.id}",
  "cidr": "${data.consul_keys.v.var.vpc_cidr}"
}
JSON

  depends_on = ["aws_vpc_peering_connection_accepter.accepter-ss-vpc"]
} 

