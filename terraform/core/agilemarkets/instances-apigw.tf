# Build the AWS Instance
resource "aws_instance" "apigw" {
  ami           = "${data.aws_ami.des-apigw-ami.id}"
  instance_type = "${data.consul_keys.apigw.var.instance_type}"
  count         = "${data.consul_keys.apigw.var.instance_count}"
  subnet_id     = "${element(data.aws_subnet_ids.intra_subnets.ids, count.index)}"
  vpc_security_group_ids = ["${data.aws_security_group.all-hosts-sg.id}","${aws_security_group.apigw-sg.id}"]
  key_name = "${local.account}-${local.environment}-key"
  associate_public_ip_address = "false"
  iam_instance_profile = "ec2-default-instance-profile"
  root_block_device {
    delete_on_termination = true
    volume_type = "gp2"
  }
  # The user data below is to make sure a rebuild is triggered when there is a new package
  user_data = <<EOF
              #!/bin/bash
              echo "${data.consul_keys.apigw.var.build_package}"
              echo "${data.consul_keys.apigw.var.rbsagile_bundle}" 
              EOF
  depends_on = ["random_string.apigw_initial_password"]
  tags = "${merge(local.default_tags, local.apigw_tags, map(
    "Name", "${local.environment}-apigw-${count.index + 1}"
  ))}"
}

resource "random_string" "apigw_initial_password" {
  # password used at build time, should be changed after build
  length = 16
  special = false
}
