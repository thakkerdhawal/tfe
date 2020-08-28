resource "aws_acm_certificate" "certupdate" {
  private_key       = "${var.key != "" ? var.key : join("", data.local_file.key.*.content)}"
  certificate_body  = "${var.cert != "" ? var.cert : join("", data.local_file.cert.*.content)}"
  certificate_chain = "${var.cert_chain != "" ? var.cert_chain : join("", data.local_file.cert_chain.*.content)}"

  tags = "${local.default_tags}"
}

