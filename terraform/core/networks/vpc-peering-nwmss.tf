##
## Configure Peering with the shared services accounts VPC and setup routing
##

# Request Peering from NWMSS to NWM
resource "aws_vpc_peering_connection" "requester-ss-vpc" {
  provider      = "aws.ss-assume"
  peer_owner_id = "${data.aws_caller_identity.current.account_id}"
  peer_vpc_id   = "${module.vpcnwm.vpc_id}" 
  vpc_id        = "${data.consul_keys.import.var.req_vpc_id}"
 # TODO: cater for cross region
  peer_region   = "${local.region}"
  auto_accept   = false
}

# Route from the intra subnets in Core VPC to Shared Service VPC in the shared services account
resource "aws_route" "corevpc-intra-to-ssvpc" {
  count = 1
  route_table_id 	    = "${element(module.vpcnwm.intra_route_table_ids, count.index)}"
  destination_cidr_block    = "${data.consul_keys.import.var.req_vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester-ss-vpc.id}"
}

# Route from the public subnets in Core VPC to Shared Service VPC in the shared services account
resource "aws_route" "corevpc-public-to-ssvpc" {
  count = 1
  route_table_id 	    = "${element(module.vpcnwm.public_route_table_ids, count.index)}"
  destination_cidr_block    = "${data.consul_keys.import.var.req_vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester-ss-vpc.id}"
}


# Accept Peering from the core account
resource "aws_vpc_peering_connection_accepter" "accepter-nwmss-core-vpc" {
  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester-ss-vpc.id}"
  auto_accept               = true
}

# Create a route in the route table on the requester side (CTO VPC)
data "aws_lambda_invocation" "create_nwmss_route_table_entry" {
  provider      = "aws.ss-assume"
  function_name = "${element(split("-",data.consul_keys.v.var.peervpc_name),0)}-create_route_table_entry"

  input = <<JSON
{
  "peering_Id": "${aws_vpc_peering_connection.requester-ss-vpc.id}",
  "cidr": "${data.consul_keys.v.var.vpc_cidr}"
}
JSON

  depends_on = ["aws_vpc_peering_connection_accepter.accepter-nwmss-core-vpc"]
}
