resource "aws_instance" "bastion-ss" {
  ami = "${data.aws_ami.des-rhel7-ami.id}"
  count = "${data.consul_keys.v.var.bastion_instance_count}"
  instance_type = "${data.consul_keys.v.var.bastion_instance_type}"
  subnet_id     = "${element(split(",",data.consul_keys.import.var.intra_subnets), count.index)}"
  vpc_security_group_ids = ["${data.consul_keys.import.var.all_hosts_sg_id}","${data.consul_keys.import.var.bastion_hosts_sg_id}"]
  associate_public_ip_address = "false"
  key_name = "${local.environment}-key" 
  root_block_device { 
    delete_on_termination = true
    volume_type = "gp2"
  }
  iam_instance_profile = "ec2-default-instance-profile"
  user_data = <<EOF
#!/bin/bash
/usr/sbin/useradd -U -u 14005 -G e0000000 -s /bin/true e0000005
/usr/bin/passwd -x 99999 e0000005
/usr/sbin/useradd -U -u 14006 -G e0000000 -s /bin/true e0000006
/usr/bin/passwd -x 99999 e0000006
/usr/sbin/useradd -U -u 14011 -G e0000000 -s /bin/true e0000011
/usr/bin/passwd -x 99999 e0000011
/usr/sbin/useradd -U -u 14047 -G e0000000 -s /bin/true e0000047
/usr/bin/passwd -x 99999 e0000047
EOF
  lifecycle {
    create_before_destroy = true
  }
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-bastionnode-${count.index + 1}"
  ))}"
}

resource "local_file" "ssh_config" {
    content     = "${data.template_file.ssh_config.rendered}"
    filename = "../../ssh_config.${terraform.workspace}"
}
