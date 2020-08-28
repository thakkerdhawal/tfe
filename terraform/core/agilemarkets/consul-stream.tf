#
# Add any extra keys you require in this section
#
data "consul_keys" "stream" {
  key {
    name = "stream_instance_count"
    path = "${local.consul_key_inputprefix}/common/stream_instance_count"
    default = ""
  }
  key {
    name = "stream_instance_type"
    path = "${local.consul_key_inputprefix}/common/stream_instance_type"
    default = ""
  }
  key {
    name = "stream_root_volume_size"
    path = "${local.consul_key_inputprefix}/common/stream_root_volume_size"
    default = ""
  }
  key {
    name = "stream_certs_agilemarkets.arns"
    path = "${local.consul_key_inputprefix}/${local.region}/stream_certs_agilemarkets.arns"
    default = ""
  }
  key {
    name = "stream_data_source_cidrs"
    path = "${local.consul_key_inputprefix}/common/stream_data_source_cidrs"
    default = ""
  }
}
