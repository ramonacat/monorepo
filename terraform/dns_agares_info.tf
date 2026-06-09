resource "ovh_domain_name_servers" "agares-info" {
  domain = "agares.info"
  servers { host = "ns1.dnsimple-edge.com" }
  servers { host = "ns2.dnsimple-edge.net" }
  servers { host = "ns3.dnsimple-edge.io" }
  servers { host = "ns4.dnsimple-edge.org" }
}

resource "dnsimple_zone" "agares-info" {
  name   = "agares.info"
  active = true
}

module "fastmail-dns--agares-info" {
  source = "./fastmail-dns"

  zone_name = dnsimple_zone.agares-info.name
}
