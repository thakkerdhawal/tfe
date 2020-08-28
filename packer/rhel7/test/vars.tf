#Define value for the variable

variable "region" {
   description = "region"
   default = "eu-west-1"
}

variable "credential_file" {
   description = "credential_file"
   default = "/home/ecommprv/.aws/credentials"
}

variable "aws_profile_ss" {
   description = "AWS account of Share Services env"
   # default = "Please provide on CLI"
}

variable "bastion" {
   description = "info required for launch a bastion host in this region"
   type = "map"
   default = {
     subnet = "subnet-6c4a5008"
     sg_id = "sg-1ac81d63"
   }
}

variable "app" {
   description = "info required for launch an app host in this region"
   type = "map"
   default = {
     subnet = "subnet-3b7f835c"
     sg_id = "sg-68057911"
   }
}

variable "ssh_key" {

}
