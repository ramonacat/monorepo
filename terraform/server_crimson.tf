module "node--crimson" {
  source = "./node"

  dns_zone_name       = dnsimple_zone.ramona-fun.name
  name                = "crimson"
  ssh_keys            = [hcloud_ssh_key.ramona.id]
  location            = "hel1"
  image               = "debian-12"
  tailscale_tags      = split(" ", data.external.tailscale_tags.result["crimson"])
  install_private_key = var.ssh_private_key
}

moved {
  from = hcloud_server.crimson
  to   = module.node--crimson.hcloud_server.node
}
moved {
  from = hcloud_rdns.crimson-ipv4
  to   = module.node--crimson.hcloud_rdns.node-ipv4
}
moved {
  from = hcloud_rdns.crimson-ipv6
  to   = module.node--crimson.hcloud_rdns.node-ipv6
}

moved {
  from = module.crimson-system-build
  to   = module.node--crimson.module.system-build
}

moved {
  from = module.crimson-disko
  to   = module.node--crimson.module.disko
}

moved {
  from = module.crimson-install
  to   = module.node--crimson.module.install
}
