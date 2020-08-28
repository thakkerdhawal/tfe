# Dummy Splunk Instance for DEV testing
resource "aws_instance" "splunk-fwd" {
  count = 1
  ami = "${data.aws_ami.des-rhel7-ami.id}"
  instance_type = "${data.consul_keys.v.var.logging_instance_type}"
  subnet_id     = "${element(data.aws_subnet_ids.private_subnets.ids, count.index)}"
  vpc_security_group_ids = ["${data.aws_security_group.all-hosts-sg.id}","${aws_security_group.splunk-fwd-sg.id}"]
  associate_public_ip_address = "false"
  key_name = "${local.environment}-key"
  root_block_device {
    delete_on_termination = true
    volume_type = "gp2"
    # volume_size = 20
  }
  iam_instance_profile = "ec2-splunkforwarder-instance-profile"
  user_data = <<EOF
#!/bin/bash
/usr/sbin/useradd -U -u 14011 -G e0000000 -s /bin/bash e0000011
/usr/bin/passwd -x 99999 e0000011
EOF
  lifecycle { create_before_destroy = true }
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-splunk-fwd-${count.index + 1}"
  ))}"
}

resource "random_string" "splunk-fwd-initial-password" {
  # password used at build time, should be changed after build
  length = 16
  special = false
}
