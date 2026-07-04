terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = ">= 0.29.2"
    }
  }
}

data "tailscale_devices" "all" {
}

locals {
  tailscale_device = lookup({ for device in data.tailscale_devices.all.devices : device.hostname => device }, var.hostname, null)
}

resource "tailscale_device_tags" "node" {
  count = local.tailscale_device == null ? 0 : 1

  device_id = local.tailscale_device.node_id
  tags      = var.tailscale_tags
}

resource "vault_pki_secret_backend_cert" "node" {
  backend               = var.vault_pki
  name                  = var.vault_role
  common_name           = var.hostname
  ttl                   = 86400
  min_seconds_remaining = 43200
  auto_renew            = true
}
