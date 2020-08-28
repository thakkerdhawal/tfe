locals {
  administrator_roles = ["ADFS-Administrator", "FMADFS-Administrator"]
  powerusers_roles = ["ADFS-PowerUsers", "FMADFS-PowerUsers"]
  readonly_roles = ["ADFS-ReadOnly", "FMADFS-ReadOnly"]
  # the variable will not be in consul for now as they are the same in all environments
  aws_managed_policy_for_admin = ["AdministratorAccess"]
  # TODO: remove IAM access
  aws_managed_policy_for_powerusers = ["ReadOnlyAccess", "IAMReadOnlyAccess", "AWSSupportAccess"]
  aws_managed_policy_for_powerusers_dev= ["IAMFullAccess"]
  aws_managed_policy_for_readonly = ["ReadOnlyAccess", "IAMReadOnlyAccess", "AWSSupportAccess"]
}

