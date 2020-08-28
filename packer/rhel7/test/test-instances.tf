# TODO: may need to have one for each region
provider "aws" {
  version = "~> 1.5"
  shared_credentials_file = "${var.credential_file}"
  region  = "eu-west-1"
  profile = "${var.aws_profile_ss}"
}

# data "aws_caller_identity" "shared-services" {
  # account id can now be referred as  ${data.aws_caller_identity.shared-services.account_id}
# }

data "aws_ami" "rhel7_ami" {
  most_recent      = true
  owners     = ["self"]
  filter {
    name   = "name"
    values = ["des-rhel7 *"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

}

resource "aws_key_pair" "ssh-key" {
  key_name = "des-rhel7-buildtest-key"
  public_key = "${file("${var.ssh_key}")}"
}

resource "aws_instance" "test-bastion" {
  ami           = "${data.aws_ami.rhel7_ami.id}"
  instance_type = "t2.micro"
  subnet_id = "${var.bastion["subnet"]}"
  vpc_security_group_ids = ["${var.bastion["sg_id"]}"]
  associate_public_ip_address = "false"
  key_name = "${aws_key_pair.ssh-key.key_name}"
  tags = {
    Name = "des-rhel7-buildtest-bastion"
  }
  # user_data = "${file("repo-server-build.sh")}"
  tags {
    "Terraform" = "true"
  }
}

output "test-bastion-ip" {
  value = "${aws_instance.test-bastion.private_ip}"
}


resource "aws_instance" "test-app" {
  ami           = "${data.aws_ami.rhel7_ami.id}"
  instance_type = "t2.micro"
  subnet_id = "${var.app["subnet"]}"
  vpc_security_group_ids = ["${var.app["sg_id"]}"]
  associate_public_ip_address = "false"
  key_name = "${aws_key_pair.ssh-key.key_name}"
  tags = {
    Name = "des-rhel7-buildtest-app"
  }
  # user_data = "${file("repo-server-build.sh")}"
  tags {
    "Terraform" = "true"
  }
}

output "test-app-ip" {
  value = "${aws_instance.test-app.private_ip}"
}

