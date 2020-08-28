#
# Blackduck RDS Instances
#

# Primary instance in London
resource "aws_db_instance" "blackduck_primary" {
  count                     = "${ local.region == "eu-west-2" ? 1:0 }"
  identifier                = "${local.environment}-blackduck-primary"
  allocated_storage         = "${ local.environment == "prod" ? 300:108 }"
  storage_type              = "gp2"
  engine                    = "postgres"
  engine_version            = "9.6"
  instance_class            = "${data.consul_keys.blackduck.var.blackduck_rds_instance_type}"
  db_subnet_group_name      = "${aws_db_subnet_group.blackduck_rds.id}"
  snapshot_identifier       = "${data.aws_db_snapshot.latest_prod_snapshot.id}"
  final_snapshot_identifier = "blackduck-final-shutdown-snapshot-${replace(timestamp(), ":", "-")}"
  vpc_security_group_ids    = ["${aws_security_group.blackduck-rds-sg.id}"]
  parameter_group_name      = "${aws_db_parameter_group.blackduck_rds.id}"
  backup_retention_period   = 30
  maintenance_window        = "Sun:00:00-Sun:03:00"
  backup_window             = "23:00-23:59"
  storage_encrypted         = true
  copy_tags_to_snapshot     = true

  lifecycle {
    # Ignore snapshot_identifier changes as it will change with the daily snapshot and we only want it for initial build
    # Also ignore final_snapshot_identifier as it changes with the timestamp each run
    ignore_changes        = ["snapshot_identifier", "final_snapshot_identifier"]
  } 
 
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck-primary-rds"
  ))}"
}

data "aws_db_snapshot" "latest_prod_snapshot" {
  count                  = "${ local.region == "eu-west-2"? 1:0 }"
  db_instance_identifier = "${local.environment}-blackduck-primary"
  most_recent            = true
}

resource "aws_db_subnet_group" "blackduck_rds" {
  count      = "${ local.region == "eu-west-2"? 1:0 }"
  name       = "${local.environment}-blackduck-rds-subnets"
  subnet_ids = ["${split(",",data.consul_keys.import.var.intra_subnets)}"]

  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck-rds-subnets"
  ))}"
}

resource "aws_db_parameter_group" "blackduck_rds" {
  count  = "${ local.region == "eu-west-2"? 1:0 }"
  name   = "${local.environment}-blackduck-rds-params"
  family = "postgres9.6"

  parameter {
    name  = "autovacuum_max_workers"
    value = "20"
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "autovacuum_vacuum_cost_limit"
    value = "2000"
    apply_method = "pending-reboot"
  }

  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck-rds-params"
  ))}"
}

