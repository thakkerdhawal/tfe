data "aws_caller_identity" "current" {}

data "local_file" "cert" {
    count = "${var.cert == "" ? 1 : 0}"
    filename = "${var.cert_path}"
}

data "local_file" "key" {
    count = "${var.key == "" ? 1 : 0}"
    filename = "${var.key_path}"
}

data "local_file" "cert_chain" {
    count = "${var.cert_chain == "" ? 1 : 0}"
    filename = "${var.cert_chain_path}"
}

