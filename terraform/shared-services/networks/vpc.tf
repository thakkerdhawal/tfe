#
# Create Main VPC. Using the AWS VPC module
#

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
module "vpcss" {
  source = "../../modules/terraform-aws-vpc"

  name = "${local.environment}-vpc"
  cidr = "${data.consul_keys.v.var.vpc_cidr}"
  # public subnets are subnets with access from Internet via Internet Gateway
  public_subnets= ["${split(",",data.consul_keys.v.var.public_subnets)}"]
  # private subnets are subnets with access to Internet via NAT Gateway
  private_subnets = ["${split(",",data.consul_keys.v.var.private_subnets)}"]
  # intra_subnets are subnets without access from/to Internet
  intra_subnets = ["${split(",",data.consul_keys.v.var.intra_subnets)}"]
  azs = ["${slice(data.aws_availability_zones.available.names,0,data.consul_keys.v.var.az_number)}"]
  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_s3_endpoint   = true

  tags = "${merge(local.default_tags, local.networks_tags, map(
    "Name", "${local.environment}-vpc"
  ))}"

  public_subnet_tags = "${merge(local.default_tags, local.networks_tags, map(
    "Name", "${local.environment}-vpc-public-${local.region}"
  ))}"
  public_route_table_tags = "${merge(local.default_tags, local.networks_tags, map(
    "Name", "${local.environment}-vpc-public-${local.region}"
  ))}"
  private_subnet_tags = "${merge(local.default_tags, local.networks_tags, map(
    "Name", "${local.environment}-vpc-private-${local.region}"
  ))}"
  private_route_table_tags = "${merge(local.default_tags, local.networks_tags, map(
    "Name", "${local.environment}-vpc-private-${local.region}"
  ))}"
  intra_subnet_tags = "${merge(local.default_tags, local.networks_tags, map(
    "Name", "${local.environment}-vpc-intra-${local.region}"
  ))}"
  intra_route_table_tags = "${merge(local.default_tags, local.networks_tags, map(
    "Name", "${local.environment}-vpc-intra-${local.region}"
  ))}"
}

resource "aws_flow_log" "vpcflow-logs" {
  log_destination      = "${data.aws_s3_bucket.logs.arn}"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = "${module.vpcss.vpc_id}"
}

#attach VPC to Virtual Private Gateway
resource "aws_vpn_gateway_attachment" "vpgss_attachment" {
  vpc_id         = "${module.vpcss.vpc_id}"
  vpn_gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
  depends_on = ["aws_vpn_gateway.vpn_gw"]
}

# Route from Intra Shared Service VPC to RBS Campus
resource "aws_route" "intra-to-oncampus" {
  count                     = 1
  route_table_id            = "${element(module.vpcss.intra_route_table_ids, count.index)}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = "${aws_vpn_gateway.vpn_gw.id}"
  depends_on = ["aws_vpn_gateway_attachment.vpgss_attachment", "aws_dx_private_virtual_interface.dxvi"]
}

# Route from Private Shared Service VPC to RBS Campus
resource "aws_route" "private-to-oncampus" {
  count                     = 1
  route_table_id            = "${element(module.vpcss.private_route_table_ids, count.index)}"
  destination_cidr_block    = "11.0.0.0/8"
  gateway_id                = "${aws_vpn_gateway.vpn_gw.id}"
  depends_on = ["aws_vpn_gateway_attachment.vpgss_attachment", "aws_dx_private_virtual_interface.dxvi"]
}

resource "aws_key_pair" "nwmsshkey" {
  key_name = "${local.environment}-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCA+5BZmts7yLEK5jVzv4OVzNLrWpPUbiZT67C4hcsQucIITLvts5pruzxtQM+7x/+7dqRluFL4PirIsu2qrZT7T3a+6SZ5x0mUksGPEpLyZIxjUIw/uHtwB82RROEDJdSgMHAadQACYDUaK1UTHqYdbXI4gYmnlSnwc4jZYmIGyKEdRDYtmslI23oM8/CCup4lgmyQXxMK7N/22sSVDwqvIoMIjX16IR8Lw4TrDsnY/6XQJAJDy4mmVXaFUE1atgeXNux7GLTfMQOnLT2rcCmpn9jVUg72wcD2e4uhvb+0WBgSbKtqlJpY7h1YkqFDiz7x8qwgRWSfNWeb55nivtgd"
}

