resource "hcloud_network" "net" {
  name     = "net"
  ip_range = "10.70.0.0/16"
}

resource "hcloud_firewall" "fw" {
  name = "fw"

  # https://tailscale.com/docs/install/cloud/hetzner
  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "41641"
    source_ips  = ["0.0.0.0/0"]
    description = "tailscale outbound"
  }

  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "3478"
    source_ips  = ["0.0.0.0/0"]
    description = "tailscale internal"
  }

  # ssh over public network is used for initial provisioning of nodes
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = ["0.0.0.0/0"]
    description = "ssh"
  }
}
