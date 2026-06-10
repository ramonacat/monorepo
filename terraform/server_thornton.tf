module "node--thornton" {
  source = "./node"

  dns_zone_name       = dnsimple_zone.ramona-fun.name
  name                = "thornton"
  ssh_keys            = [hcloud_ssh_key.ramona.id]
  location            = "hel1"
  image               = "debian-12"
  tailscale_tags      = split(" ", data.external.tailscale_tags.result["thornton"])
  install_private_key = var.ssh_private_key
}

resource "hcloud_volume" "thornton-db" {
  name      = "thornton-db"
  size      = 50
  server_id = module.node--thornton.server_id
}

moved {
  from = hcloud_server.thornton
  to   = module.node--thornton.hcloud_server.node
}
moved {
  from = hcloud_rdns.thornton-ipv4
  to   = module.node--thornton.hcloud_rdns.node-ipv4
}
moved {
  from = hcloud_rdns.thornton-ipv6
  to   = module.node--thornton.hcloud_rdns.node-ipv6
}

moved {
  from = module.thornton-system-build
  to   = module.node--thornton.module.system-build
}

moved {
  from = module.thornton-disko
  to   = module.node--thornton.module.disko
}

moved {
  from = module.thornton-install
  to   = module.node--thornton.module.install
}
