// TODO this should be in the node module
data "external" "tailscale_tags" {
  program = ["bash", abspath("./scripts/external-tailscale-tags.bash")]
}

data "tailscale_device" "pikvm" {
  hostname = "pikvm"
}

data "tailscale_device" "hallewell" {
  hostname = "hallewell"
}

data "tailscale_device" "shadowsoul" {
  hostname = "shadowsoul"
}

moved {
  from = tailscale_device_tags.tags
  to   = tailscale_device_tags.devices
}

resource "tailscale_device_tags" "pikvm" {
  device_id = data.tailscale_device.pikvm.node_id
  tags      = ["tag:server", "tag:server-private", "tag:server-private-home"]
}

removed {
  from = tailscale_device_tags.devices

  lifecycle {
    destroy = false
  }
}

// TODO create a module for physical machines that sets up dns, tailscale tags, etc.
resource "tailscale_device_tags" "hallewell" {
  device_id = data.tailscale_device.hallewell.node_id
  tags      = split(" ", data.external.tailscale_tags.result["hallewell"])
}

resource "tailscale_device_tags" "shadowsoul" {
  device_id = data.tailscale_device.shadowsoul.node_id
  tags      = split(" ", data.external.tailscale_tags.result["shadowsoul"])
}

resource "tailscale_dns_configuration" "default" {
  override_local_dns = true

  nameservers {
    address            = "8.8.8.8"
    use_with_exit_node = false
  }
}
