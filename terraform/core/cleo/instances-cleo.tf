# Provision the Cleo VLProxy Ingress Instance(s) - 1 per region

resource "aws_instance" "vlproxy-ingress" {
  ami = "${data.aws_ami.des-rhel7-ami.id}"
  count         = "1"
  iam_instance_profile = "ec2-default-instance-profile"
  instance_type = "${data.consul_keys.v.var.vlproxy_ingress_instance_type}"
  subnet_id     = "${element(data.aws_subnet_ids.intra_subnets.ids, count.index)}"
  associate_public_ip_address = "false"
  vpc_security_group_ids = ["${data.aws_security_group.all-hosts-sg.id}", "${aws_security_group.vlproxy-ingress-sg.id}", "${aws_security_group.vlproxy-dnshealthcheck-sg.id}"]
  key_name = "${local.account}-${local.environment}-key"
  root_block_device {
  	volume_type = "gp2"
  	volume_size = "${data.consul_keys.v.var.vlproxy_root_volume_size}"
  	delete_on_termination = "true"
               }
  user_data = <<EOF
#!/bin/bash
/usr/sbin/useradd -U -u 14047 -G e0000000 -s /bin/bash e0000047
/usr/bin/passwd -x 99999 e0000047
EOF
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-vlproxy-${count.index + 1}"
  ))}"
}

