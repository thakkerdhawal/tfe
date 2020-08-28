data "template_file" "stream_netscaler_update" {
  count    = "${data.consul_keys.stream.var.stream_instance_count}"
  template = "set server $${name} -IPAddress $${ip}"

  vars {
    name = "${lookup(local.stream_env, local.environment, "*IGNORE THIS*")}stream${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}"
    ip   = "${element(aws_instance.stream.*.private_ip, count.index)}"
  }
}

output "stream_netscaler_update" {
  description = "Commands to run on the netscaler to update the config"
  value       = "\n***** IMPORTANT - When the Liberator instances are rebuilt the following netscaler commmands need to run for Prod and NonProd (Please Ignore for Lab/Test envs)\n${join("\n", data.template_file.stream_netscaler_update.*.rendered)}\n*****\nAlso for all environments the Ansible playbook will need to be run\nansible-playbook playbooks/stream/stream_setup.yml -e \"awsEnv=${local.environment}\" -e \"awsRegion=${local.region}\" -e \"streamStatusPassword=xxx\""
}

