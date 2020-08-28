#
# Variables
#

## Static variables
locals  {
  # Default tags for most AWS resources
  default_tags = {
    "Terraform" = "Yes"
    "Environment" = "${local.environment}"
    "Component" = "${local.component}"
    "Workspace" = "${terraform.workspace}"
  }

  ## workspace naming convention: <env>_<acc>_<components>_<region>
  environment = "${element(split("_",terraform.workspace),0)}"
  account = "${element(split("_",terraform.workspace),1)}"
  component = "${element(split("_",terraform.workspace),2)}"
  region = "${element(split("_",terraform.workspace),3)}"

}

## Required input variables

variable "aws_profile" {
   description = "aws profile"
   default = ""
}

variable "credential_file" {
   description = "path to cred file "
   default = ""
}

variable "key" {
   description = ""
   default = ""
}

variable "key_path" {
   description = ""
   default = ""
}

variable "cert" {
   description = ""
   default = ""
}

variable "cert_path" {
   description = ""
   default = ""
}

variable "cert_chain" {
   description = ""
   default = ""
}

variable "cert_chain_path" {
   description = ""
   default = ""
}
