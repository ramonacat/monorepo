resource "ovh_domain_name_servers" "savin-gallery" {
  domain = "savin.gallery"
  servers { host = "ns1.dnsimple-edge.com" }
  servers { host = "ns2.dnsimple-edge.net" }
  servers { host = "ns3.dnsimple-edge.io" }
  servers { host = "ns4.dnsimple-edge.org" }
}

resource "dnsimple_zone" "savin-gallery" {
  name   = "savin.gallery"
  active = true
}

