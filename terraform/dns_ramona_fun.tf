resource "ovh_domain_name_servers" "ramona-fun" {
  domain = "ramona.fun"

  servers { host = "ns1.dnsimple-edge.com" }
  servers { host = "ns2.dnsimple-edge.net" }
  servers { host = "ns3.dnsimple-edge.io" }
  servers { host = "ns4.dnsimple-edge.org" }
}

// TODO get this from tailscale provider instead of hardcoding
variable "hallewell_tailscale_ip_address" {
  type    = string
  default = "100.109.240.138"
}

moved {
  from = dnsimple_zone_record.MX-1--ramona-fun
  to   = module.fastmail-dns--ramona-fun.dnsimple_zone_record.MX-1
}
moved {
  from = dnsimple_zone_record.MX-2--ramona-fun
  to   = module.fastmail-dns--ramona-fun.dnsimple_zone_record.MX-2
}
moved {
  from = dnsimple_zone_record.CNAME--fm1-_domainkey-ramona-fun
  to   = module.fastmail-dns--ramona-fun.dnsimple_zone_record.CNAME--fm1-_domainkey
}
moved {
  from = dnsimple_zone_record.CNAME--fm2-_domainkey-ramona-fun
  to   = module.fastmail-dns--ramona-fun.dnsimple_zone_record.CNAME--fm2-_domainkey
}
moved {
  from = dnsimple_zone_record.CNAME--fm3-_domainkey-ramona-fun
  to   = module.fastmail-dns--ramona-fun.dnsimple_zone_record.CNAME--fm3-_domainkey
}
moved {
  from = dnsimple_zone_record.TXT--ramona-fun
  to   = module.fastmail-dns--ramona-fun.dnsimple_zone_record.TXT
}
moved {
  from = dnsimple_zone_record.TXT--_dmarc-ramona-fun
  to   = module.fastmail-dns--ramona-fun.dnsimple_zone_record.TXT--_dmarc
}

resource "dnsimple_zone" "ramona-fun" {
  name   = "ramona.fun"
  active = true
}

module "fastmail-dns--ramona-fun" {
  source = "./fastmail-dns"

  zone_name = dnsimple_zone.ramona-fun.name
}

resource "dnsimple_zone_record" "A--ras2-services-ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = "ras2.services"
  type      = "A"
  value     = var.hallewell_tailscale_ip_address
  ttl       = 60
}


resource "dnsimple_zone_record" "A--ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = ""
  type      = "A"
  value     = module.node--crimson.ipv4
  ttl       = 60
}

resource "dnsimple_zone_record" "AAAA--ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = ""
  type      = "AAAA"
  value     = module.node--crimson.ipv6
  ttl       = 60
}

moved {
  from = dnsimple_zone_record.A--crimson-devices-ramona-fun
  to   = module.node--crimson.dnsimple_zone_record.A--node
}

moved {
  from = dnsimple_zone_record.AAAA--crimson-devices-ramona-fun
  to   = module.node--crimson.dnsimple_zone_record.AAAA--node
}

moved {
  from = dnsimple_zone_record.A--thornton-devices-ramona-fun
  to   = module.node--thornton.dnsimple_zone_record.A--node
}

moved {
  from = dnsimple_zone_record.AAAA--thornton-devices-ramona-fun
  to   = module.node--thornton.dnsimple_zone_record.AAAA--node
}

moved {
  from = dnsimple_zone_record.A--thronton-devices-ramona-fun
  to   = dnsimple_zone_record.A--thornton-devices-ramona-fun
}

moved {
  from = dnsimple_zone_record.AAAA--thronton-devices-ramona-fun
  to   = dnsimple_zone_record.AAAA--thornton-devices-ramona-fun
}

resource "dnsimple_zone_record" "CNAME--jellyfin-ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = "jellyfin"
  type      = "CNAME"
  value     = "cb380c2c50bc.sn.mynetname.net."
  ttl       = 60
}
