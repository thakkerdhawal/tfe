data "aws_ami" "redhat-rhel6-ami" {
  count = "${local.environment == "lab" && local.region == "eu-west-2" ? 1 : 0}"
  most_recent      = true
  name_regex       = "RHEL-6\\.\\d{1,2}_HVM_GA"
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  owners     = ["309956199498"]
}

resource "aws_instance" "apache-dev" {
  count = "${local.environment == "lab" && local.region == "eu-west-2" ? 1 : 0}"
  ami = "${data.aws_ami.redhat-rhel6-ami.id}"
  instance_type = "t2.micro"
  subnet_id     = "${element(split(",",data.consul_keys.import.var.intra_subnets), count.index)}"
  vpc_security_group_ids = ["${data.consul_keys.import.var.all_hosts_sg_id}"]
  associate_public_ip_address = "false"
  key_name = "${local.environment}-key" 
  root_block_device { 
    delete_on_termination = true
    volume_type = "gp2"
  }
  iam_instance_profile = "ec2-default-instance-profile"
  user_data = <<EOF
#!/bin/bash
setenforce 0
/usr/sbin/groupadd -g 2000 e0000000
/usr/sbin/useradd -U -u 14010 -G e0000000 -s /bin/bash e0000010
/usr/bin/passwd -x 99999 e0000010
/usr/sbin/useradd -U -u 14011 -G e0000000 -s /bin/bash e0000011
/usr/bin/passwd -x 99999 e0000011
EOF
  tags = "${merge(local.default_tags, map(
    "Name", "${local.environment}-apache-dev-${count.index + 1}",
    "Owner", "Beiming Wang",
    "JIRA", "ENGGCOE-2555"
  ))}"
}

output "apache-dev_hosts_private_ips" {
  description = "The private IP addresses of Apache Dev host"
  value       = "${aws_instance.apache-dev.*.private_ip}"
}

