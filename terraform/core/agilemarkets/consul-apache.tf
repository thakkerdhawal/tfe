## Add any extra keys you require in this section
#
data "consul_keys" "apache" {
  key {
    name = "instance_type"
    path = "${local.consul_key_inputprefix}/common/apache_instance_type"
    default = ""
  }
  key {
    name = "instance_count"
    path = "${local.consul_key_inputprefix}/common/apache_instance_count"
    default = ""
  }
  key {
    name = "backends"
    path = "${local.consul_key_inputprefix}/common/apache_backends"
    default = ""
  }
}

