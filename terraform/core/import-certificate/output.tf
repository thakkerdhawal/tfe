output "Certificate" {
  description = "AWS ARN of uploaded certificate"
  value       = "\n\nCertificate imported\nAccount=${data.aws_caller_identity.current.account_id}\nRegion=${local.region}\nCertificate name=${aws_acm_certificate.certupdate.domain_name}\nCertificate ARN=${aws_acm_certificate.certupdate.arn}\n\nUpdate the consul configuration in https://stash.dts.fm.rbsgrp.net/projects/DEP/repos/nwm_infra_tf_engineering/browse/consul/\n\n** Please remember to remove the state file in ./terraform.tfstate.d to prevent accidental deletion of this certificate.\n"
}

