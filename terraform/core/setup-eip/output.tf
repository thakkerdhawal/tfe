#### Consul Output ####
resource "consul_key_prefix" "consul_output" {
  path_prefix = "${local.consul_key_outputprefix}/"
  subkeys {
    "cleo_eip_public_ip" = "${join(",",aws_eip.cleo.*.public_ip)}"
    "fxmp_eip_public_ip_1" = "${join(",",aws_eip.fxmp-1.*.public_ip)}"
    "fxmp_eip_public_ip_2" = "${join(",",aws_eip.fxmp-2.*.public_ip)}"
    "fxmp_eip_public_ip_3" = "${join(",",aws_eip.fxmp-3.*.public_ip)}"
    "fxmp_int_eip_public_ip_1" = "${join(",",aws_eip.fxmp-int-1.*.public_ip)}"
    "fxmp_int_eip_public_ip_2" = "${join(",",aws_eip.fxmp-int-2.*.public_ip)}"
    "fxmp_int_eip_public_ip_3" = "${join(",",aws_eip.fxmp-int-3.*.public_ip)}"

   ## US
    "fxmp_us_eip_public_ip_1" = "${join(",",aws_eip.fxmp-us-1.*.public_ip)}"
    "fxmp_us_eip_public_ip_2" = "${join(",",aws_eip.fxmp-us-2.*.public_ip)}"
    "fxmp_us_eip_public_ip_3" = "${join(",",aws_eip.fxmp-us-3.*.public_ip)}"
    "fxmp_int_us_eip_public_ip_1" = "${join(",",aws_eip.fxmp-int-us-1.*.public_ip)}"
    "fxmp_int_us_eip_public_ip_2" = "${join(",",aws_eip.fxmp-int-us-2.*.public_ip)}"
    "fxmp_int_us_eip_public_ip_3" = "${join(",",aws_eip.fxmp-int-us-3.*.public_ip)}"
  }
} 

output "cleo_eip_public_ip" {
  description = "Cleo Public IP of EIP1"
  value       = "${aws_eip.cleo.*.public_ip}"
}

output "fxmp_eip_public_ip_1" {
  description = "FXMP Public IP of EIP1"
  value       = "${aws_eip.fxmp-1.*.public_ip}"
}

output "fxmp_eip_public_ip_2" {
  description = "FXMP Public IP of EIP2"
  value       = "${aws_eip.fxmp-2.*.public_ip}"
}

output "fxmp_eip_public_ip_3" {
  description = "FXMP Public IP of EIP3"
  value       = "${aws_eip.fxmp-3.*.public_ip}"
}

output "fxmp_int_eip_public_ip_1" {
  description = "FXMP INT Public IP of EIP1"
  value       = "${join(",",aws_eip.fxmp-int-1.*.public_ip)}"
}

output "fxmp_int_eip_public_ip_2" {
  description = "FXMP INT Public IP of EIP2"
  value       = "${join(",",aws_eip.fxmp-int-2.*.public_ip)}"
}

output "fxmp_int_eip_public_ip_3" {
  description = "FXMP INT Public IP of EIP3"
  value       = "${join(",",aws_eip.fxmp-int-3.*.public_ip)}"
}

##US EIP

output "fxmp_us_eip_public_ip_1" {
  description = "FXMP Public IP of EIP1"
  value       = "${aws_eip.fxmp-us-1.*.public_ip}"
}

output "fxmp_us_eip_public_ip_2" {
  description = "FXMP Public IP of EIP2"
  value       = "${aws_eip.fxmp-us-2.*.public_ip}"
}

output "fxmp_us_eip_public_ip_3" {
  description = "FXMP Public IP of EIP3"
  value       = "${aws_eip.fxmp-us-3.*.public_ip}"
}

output "fxmp_int_us_eip_public_ip_1" {
  description = "FXMP US INT Public IP of EIP1"
  value       = "${join(",",aws_eip.fxmp-int-us-1.*.public_ip)}"
}

output "fxmp_int_us_eip_public_ip_2" {
  description = "FXMP US INT Public IP of EIP2"
  value       = "${join(",",aws_eip.fxmp-int-us-2.*.public_ip)}"
}

output "fxmp_int_us_eip_public_ip_3" {
  description = "FXMP US INT Public IP of EIP3"
  value       = "${join(",",aws_eip.fxmp-int-us-3.*.public_ip)}"
}
