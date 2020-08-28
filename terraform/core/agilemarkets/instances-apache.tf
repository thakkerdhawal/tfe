resource "aws_instance" "apache" {
  ami = "${data.aws_ami.des-rhel7-ami.id}"
  count = "${data.consul_keys.apache.var.instance_count}"
  instance_type = "${data.consul_keys.apache.var.instance_type}"
  subnet_id     = "${element(data.aws_subnet_ids.intra_subnets.ids, count.index)}"
  vpc_security_group_ids = ["${data.aws_security_group.all-hosts-sg.id}","${aws_security_group.apache-sg.id}"]
  root_block_device {
    delete_on_termination = true
    volume_type = "gp2"
  }
  associate_public_ip_address = "false"
  key_name = "${local.account}-${local.environment}-key"
  iam_instance_profile = "ec2-default-instance-profile"
  user_data = <<EOF
#!/bin/bash
/usr/sbin/useradd -U -u 14005 -G e0000000 -s /bin/bash e0000005
/usr/bin/passwd -x 99999 e0000005
/usr/sbin/useradd -U -u 14006 -G e0000000 -s /bin/bash e0000006
/usr/bin/passwd -x 99999 e0000006
EOF
  tags = "${merge(local.default_tags, local.apache_tags,  map(
    "Name", "${local.environment}-apache-reverse-proxy-${count.index + 1}"
  ))}"
  lifecycle {
    create_before_destroy = true
  } 
}
