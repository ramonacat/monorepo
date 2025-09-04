data "external" "tailscale-tags" {
  program = ["bash", abspath("./scripts/external-tailscale-tags.bash")]
}

data "tailscale_devices" "all" {
}

data "tailscale_device" "pikvm" {
  hostname = "pikvm"
}

resource "tailscale_device_tags" "tags" {
  for_each  = data.external.tailscale-tags.result
  device_id = lookup({ for device in data.tailscale_devices.all.devices : device.hostname => device.node_id }, each.key)
  tags      = split(" ", each.value)
}

resource "tailscale_device_tags" "pikvm" {
  device_id = data.tailscale_device.pikvm.node_id
  tags      = ["tag:server", "tag:server-private", "tag:server-private-home"]
}
