data "aws_ami" "des-rhel7-ami" {
  # We do not allow multiple AMI with same version
  most_recent      = false
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "tag:Name"
    values = ["nwm-rhel7-ami"]
  }
  filter {
    name   = "tag:Version"
    values = ["${data.consul_keys.v.var.des_rhel7_ami_version_filter}"]
  }
  owners     = ["self"]
}

data "template_file" "ssh_config" {
  template = "${file("ssh_config_output.tmpl")}"
  vars {
    env_name = "${local.account}-${local.environment}"
    ip = "${aws_instance.bastion-ss.0.private_ip}"
  }
}
