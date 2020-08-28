#### Consul Output ####
resource "consul_key_prefix" "consul_output" {
  path_prefix = "${local.consul_key_outputprefix}/"
  subkeys {
    "logging_splunk_web_private_ips" = "${join(",",aws_instance.splunk-web.*.private_ip)}"
    "logging_splunk_web_lb_fqdn" = "${join(",",aws_lb.lb-splunk-web-int.*.dns_name)}"
    "logging_splunk_web_initial_password" = "${join(",",random_string.splunk-web-initial-password.*.result)}"
    "logging_splunk_fwd_private_ips" = "${join(",",aws_instance.splunk-fwd.*.private_ip)}"
    "logging_splunk_fwd_lb_fqdn" = "${join(",",aws_lb.lb-splunk-fwd-int.*.dns_name)}"
    "logging_splunk_fwd_initial_password" = "${join(",",random_string.splunk-fwd-initial-password.*.result)}"
  }
}

output "logging_splunk_web_private_ips" {
  description = "The private IP addresses of logging hosts"
  # this syntax is to workaround for conditional outputs
  value = "${join(",",aws_instance.splunk-web.*.private_ip)}"
}

output "logging_splunk_web_lb_fqdn" {
  description = "The FQDN of Splunk Web LB"
  value = "${join(",",aws_lb.lb-splunk-web-int.*.dns_name)}"
}

output "logging_splunk_fwd_private_ips" {
  description = "The private IP addresses of logging hosts"
  value = "${join(",",aws_instance.splunk-fwd.*.private_ip)}"
}

output "logging_splunk_fwd_lb_fqdn" {
  description = "The FQDN of Splunk FWD LB"
  value = "${join(",",aws_lb.lb-splunk-fwd-int.*.dns_name)}"
}

output "apigw_ansible_playbooks" {
  description = "Playbooks to run after infrastructure provisioning"
  value       = <<EOF

**** After the logging server is built, the following Ansible Playbooks need to be executed to complete the build ****
(LAB Only) ansible-playbook playbooks/logging/logging_setup.yml -e 'awsEnv=${local.environment} awsRegion=${local.region} splunkRole=splunk_web' [-e adminPassword='XXXXX']
ansible-playbook playbooks/logging/logging_setup.yml -e 'awsEnv=${local.environment} awsRegion=${local.region} splunkRole=splunk_fwd' [-e adminPassword='XXXXX']
EOF
}

