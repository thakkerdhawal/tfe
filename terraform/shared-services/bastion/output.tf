#### Consul Output ####
resource "consul_key_prefix" "consul_output" {
  path_prefix = "${local.consul_key_outputprefix}/"
  subkeys {
    "bastion_hosts_ids" = "${join(",",aws_instance.bastion-ss.*.id)}"
    "bastion_hosts_private_ips" = "${join(",",aws_instance.bastion-ss.*.private_ip)}"
  }
}

output "bastion_hosts_private_ips" {
  description = "The private IP addresses of Bastion hosts"
  value       = "${aws_instance.bastion-ss.*.private_ip}"
}
output "ssh_config_output" {
  value = "${data.template_file.ssh_config.rendered}"
}

output "apigw_ansible_playbooks" {
  description = "Playbooks to run after infrastructure provisioning"
  value       = <<EOF

**** After the bastion server is built, the following Ansible Playbooks need to be executed to update your local sshconfig ****
ansible-playbook playbooks/awsProxyJump.yml
EOF
}
