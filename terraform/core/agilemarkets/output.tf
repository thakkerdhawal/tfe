#### Consul Output ####
resource "consul_key_prefix" "consul_output" {
  path_prefix = "${local.consul_key_outputprefix}/"
  subkeys {
    "apigw_instances_private_ip" = "${join(",",aws_instance.apigw.*.private_ip)}"
    "apigw_rbsagile_bundle_version" = "${data.consul_keys.apigw.var.rbsagile_bundle}"
    "apigw_build_package" = "${data.consul_keys.apigw.var.build_package}"
    "apigw_initial_password" = "${random_string.apigw_initial_password.result}"
    "stream_dns_glue_records" = "${join(",",aws_route53_record.stream_dnsrecord_agilemarkets.*.fqdn)}"
    "stream_instances_private_ips" = "${join(",",aws_instance.stream.*.private_ip)}"
    "apache_instances_private_ips" = "${join(",",aws_instance.apache.*.private_ip)}"
  }
}

#### Terraform Output ####
output "apigw_instances_private_ip" {
  value = ["${aws_instance.apigw.*.private_ip}"]
}

output "stream_dns_glue_records" {
  description = "Streaming Rates DNS Glue Records"
  value       = "${aws_route53_record.stream_dnsrecord_agilemarkets.*.fqdn}"
}

output "stream_instances_private_ip" {
  value = ["${aws_instance.stream.*.private_ip}"]
}

output "apigw_rbsagile_bundle_version" {
  description = "Version of RBSAgile migration bundle"
  value = "${data.consul_keys.apigw.var.rbsagile_bundle}"
}

output "apigw_build_package_version" {
  description = "Version of build package"
  value = "${data.consul_keys.apigw.var.build_package}"
}

output "apache_instances_private_ips" {
  value = ["${aws_instance.apache.*.private_ip}"]
}
