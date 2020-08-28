#### Terraform Outputs ####

output "vlproxy_ingress_private_ips" {
  value = ["${aws_instance.vlproxy-ingress.*.private_ip}"]
  description = "The private IP of the vlproxy instance"
}

output "vlproxy_nlb_fqdn" {
  value = ["${aws_lb.nlb-vlproxy-ingress.dns_name}"]
  description = "The dns address of the nlb for vlproxy"
}

output "vlproxy_dns_glue_record" {
  value = ["${aws_route53_record.vlproxydnsrecord.fqdn}"]
  description = "The DNS Glue record to access vlproxy via Route 53"
}

#### Consul Outputs ####
resource "consul_key_prefix" "consul_output" {
  path_prefix = "${local.consul_key_outputprefix}/"
  subkeys {
    "vlproxy_ingress_private_ips" = "${join(",",aws_instance.vlproxy-ingress.*.private_ip)}"
    "vlproxy_nlb_fqdn" = "${aws_lb.nlb-vlproxy-ingress.dns_name}"
    "vlproxy_dns_glue_record" = "${aws_route53_record.vlproxydnsrecord.fqdn}"
  }
}


