resource "ovh_domain_name_servers" "sawin-gallery" {
  domain = "sawin.gallery"
  servers { host = "ns1.dnsimple-edge.com" }
  servers { host = "ns2.dnsimple-edge.net" }
  servers { host = "ns3.dnsimple-edge.io" }
  servers { host = "ns4.dnsimple-edge.org" }
}
resource "dnsimple_zone" "sawin-gallery" {
  name   = "sawin.gallery"
  active = true
}

