resource "ovh_domain_name_servers" "luczkiewi-cz" {
  domain = "luczkiewi.cz"
  servers { host = "ns1.dnsimple-edge.com" }
  servers { host = "ns2.dnsimple-edge.net" }
  servers { host = "ns3.dnsimple-edge.io" }
  servers { host = "ns4.dnsimple-edge.org" }
}
resource "dnsimple_zone" "luczkiewi-cz" {
  name   = "luczkiewi.cz"
  active = true
}

module "fastmail-dns--luczkiewi-cz" {
  source = "./fastmail-dns"

  zone_name = dnsimple_zone.luczkiewi-cz.name
}
