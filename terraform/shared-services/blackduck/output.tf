#### Consul Output ####
resource "consul_key_prefix" "consul_output" {
  path_prefix = "${local.consul_key_outputprefix}/"
  subkeys {
    "blackduck_id" = "${join(",",aws_instance.blackduck-hub.*.id)}"
    "blackduck_private_ips" = "${join(",",aws_instance.blackduck-hub.*.private_ip)}"
    "blackduck_ext_alb_dns" = "${join(",",aws_lb.blackduck.*.dns_name)}"
    "blackduck_int_alb_dns" = "${join(",",aws_lb.blackduck-int.*.dns_name)}"
    "blackduck_rds" = "${join("", aws_db_instance.blackduck_primary.*.address)}"
  }
}

output "blackduck_private_ips" {
  description = "The private IP addresses of Blackduck hosts"
  value       = "${aws_instance.blackduck-hub.*.private_ip}"
}

output "blackduck_ext_alb_dns" {
  description = "The DNS name of Blackduck External ALB"
  value       = "${aws_lb.blackduck.*.dns_name}"
}

output "blackduck_int_alb_dns" {
  description = "The DNS name of Blackduck Internal ALB"
  value       = "${aws_lb.blackduck-int.*.dns_name}"
}

output "blackduck_rds" {
  value = "${join("", aws_db_instance.blackduck_primary.*.address)}"
}
