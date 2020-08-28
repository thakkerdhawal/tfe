resource "aws_instance" "blackduck-hub" {
  count = "${ local.region == "eu-west-2"? 1:0 }"
  ami           = "${data.consul_keys.blackduck.var.blackduck_ami}"
  instance_type = "${data.consul_keys.blackduck.var.blackduck_instance_type}"
  subnet_id     = "${element(split(",",data.consul_keys.import.var.private_subnets), count.index)}"
  vpc_security_group_ids = ["${data.consul_keys.import.var.all_hosts_sg_id}","${aws_security_group.blackduck-hub-sg.id}"]
  key_name = "${local.environment}-key"
  ebs_optimized = "true"
  iam_instance_profile = "ec2-default-instance-profile"
  root_block_device {
    volume_type = "gp2"
    volume_size = "${data.consul_keys.blackduck.var.blackduck_rootsize}"
    delete_on_termination = true 
  }
  lifecycle {
    create_before_destroy = true
  }
  user_data = <<EOF
#!/bin/bash
/usr/sbin/useradd -U -u 1001 -s /bin/bash ec2-user
/usr/bin/passwd -x 99999 ec2-user
/bin/cp -a /home/centos/.ssh/ /home/ec2-user/
/bin/chown -R ec2-user.ec2-user /home/ec2-user/.ssh
echo "ec2-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ec2-user
EOF
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-blackduck"
  ))}"
}

