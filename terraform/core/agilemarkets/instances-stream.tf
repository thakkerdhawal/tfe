# Build the Liberator AWS Instance
resource "aws_instance" "stream" {
  ami           = "${data.aws_ami.des-rhel7-ami.id}"
  instance_type = "${data.consul_keys.stream.var.stream_instance_type}"
  count         = "${data.consul_keys.stream.var.stream_instance_count}"
  subnet_id     = "${element(data.aws_subnet_ids.intra_subnets.ids, count.index)}"
  vpc_security_group_ids = ["${data.aws_security_group.all-hosts-sg.id}","${aws_security_group.stream-sg.id}"]
  key_name = "${local.account}-${local.environment}-key"
  user_data = <<EOF
#!/bin/bash
/usr/sbin/useradd -U -u 14005 -G e0000000 -s /bin/bash e0000005
/usr/bin/passwd -x 99999 e0000005
EOF
  root_block_device {
    delete_on_termination = true
    volume_type = "gp2"
    volume_size = "${data.consul_keys.stream.var.stream_root_volume_size}"
  }
  associate_public_ip_address = "false"
  iam_instance_profile = "ec2-default-instance-profile"
  tags = "${merge(local.default_tags, local.agilemarkets_tags, map(
    "Name", "${local.environment}-stream${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}"
  ))}"
}

# Lambda Invoke to add Liberator instance to Shared Services management ALB
data "aws_lambda_invocation" "add-stream-instance-to-mgmt-alb" {
  provider      = "aws.ss-assume"
  count         = "${data.consul_keys.stream.var.stream_instance_count}"
  function_name = "${local.ss_environment}-add-instance-to-mgmt-alb"

  input = <<JSON
{
  "targetgroup_Name": "${local.environment}-stream-mgmt-${count.index * 2 + (local.region == "eu-west-2" ? 1 : 2)}-tg",
  "instance_IP": "${element(aws_instance.stream.*.private_ip, count.index)}"
}
JSON

  depends_on = ["aws_instance.stream"]
}

