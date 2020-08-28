#
# Add any extra keys you require in this section
#
data "consul_keys" "fxmp" {
  # Common: same in both regions
  key {
    name = "public_alb_allowed_cidrs"
    path = "${local.consul_key_inputprefix}/common/public_alb_allowed_cidrs"
    default = ""
  }
}
