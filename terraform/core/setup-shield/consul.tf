data "consul_keys" "shield" {
  key {
    name = "shield_notification_email"
    path = "${local.consul_key_inputprefix}/common/shield_notification_email"
    default = ""
  }
}
