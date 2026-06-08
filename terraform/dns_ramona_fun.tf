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
  source    = "./fastmail-dns"
  zone_name = dnsimple_zone.ramona-fun.name
}

resource "google_dns_managed_zone" "ramona-fun" {
  name        = "ramona-fun"
  dns_name    = "ramona.fun."
  description = "ramona.fun"
}

resource "dnsimple_zone_record" "A--ras2-services-ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = "ras2.services"
  type      = "A"
  value     = var.hallewell_tailscale_ip_address
  ttl       = 60
}

resource "google_dns_record_set" "ras2-services-ramona-fun" {
  name         = "ras2.services.${google_dns_managed_zone.ramona-fun.dns_name}"
  type         = "A"
  ttl          = "60"
  managed_zone = google_dns_managed_zone.ramona-fun.name

  rrdatas = [var.hallewell_tailscale_ip_address]
}

resource "dnsimple_zone_record" "A--ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = ""
  type      = "A"
  value     = hcloud_server.crimson.ipv4_address
  ttl       = 60
}

resource "google_dns_record_set" "A-ramona-fun" {
  name         = google_dns_managed_zone.ramona-fun.dns_name
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "A"
  ttl          = "60"

  rrdatas = [
    hcloud_server.crimson.ipv4_address
  ]
}
resource "dnsimple_zone_record" "AAAA--ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = ""
  type      = "AAAA"
  value     = hcloud_server.crimson.ipv6_address
  ttl       = 60
}

resource "google_dns_record_set" "AAAA-ramona-fun" {
  name         = google_dns_managed_zone.ramona-fun.dns_name
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "AAAA"
  ttl          = "60"

  rrdatas = [
    hcloud_server.crimson.ipv6_address
  ]
}

resource "dnsimple_zone_record" "A--crimson-devices-ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = "crimson.devices"
  type      = "A"
  value     = hcloud_server.crimson.ipv4_address
  ttl       = 60
}

resource "google_dns_record_set" "A-crimson-devices-ramona-fun" {
  name         = "crimson.devices.${google_dns_managed_zone.ramona-fun.dns_name}"
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "A"
  ttl          = "60"

  rrdatas = [
    hcloud_server.crimson.ipv4_address
  ]
}

resource "dnsimple_zone_record" "AAAA--crimson-devices-ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = "crimson.devices"
  type      = "AAAA"
  value     = hcloud_server.crimson.ipv6_address
  ttl       = 60
}

resource "google_dns_record_set" "AAAA-crimson-devices-ramona-fun" {
  name         = "crimson.devices.${google_dns_managed_zone.ramona-fun.dns_name}"
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "AAAA"
  ttl          = "60"

  rrdatas = [
    hcloud_server.crimson.ipv6_address
  ]
}
resource "dnsimple_zone_record" "A--thronton-devices-ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = "thronton.devices"
  type      = "A"
  value     = hcloud_server.thornton.ipv4_address
  ttl       = 60
}

resource "google_dns_record_set" "A-thornton-devices-ramona-fun" {
  name         = "thornton.devices.${google_dns_managed_zone.ramona-fun.dns_name}"
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "A"
  ttl          = "60"

  rrdatas = [
    hcloud_server.thornton.ipv4_address
  ]
}

resource "dnsimple_zone_record" "AAAA--thronton-devices-ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = "thronton.devices"
  type      = "AAAA"
  value     = hcloud_server.thornton.ipv6_address
  ttl       = 60
}

resource "google_dns_record_set" "AAAA-thornton-devices-ramona-fun" {
  name         = "thornton.devices.${google_dns_managed_zone.ramona-fun.dns_name}"
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "AAAA"
  ttl          = "60"

  rrdatas = [
    hcloud_server.thornton.ipv6_address
  ]
}

resource "google_dns_record_set" "MX-ramona-fun" {
  name         = google_dns_managed_zone.ramona-fun.dns_name
  managed_zone = google_dns_managed_zone.ramona-fun.name
  ttl          = "60"
  type         = "MX"

  rrdatas = [
    "10 in1-smtp.messagingengine.com.",
    "20 in2-smtp.messagingengine.com."
  ]
}

resource "google_dns_record_set" "CNAME-fm1-_domainkey-ramona-fun" {
  name         = "fm1._domainkey.${google_dns_managed_zone.ramona-fun.dns_name}"
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "CNAME"
  ttl          = "60"

  rrdatas = ["fm1.ramona.fun.dkim.fmhosted.com."]
}

resource "google_dns_record_set" "CNAME-fm2-_domainkey-ramona-fun" {
  name         = "fm2._domainkey.${google_dns_managed_zone.ramona-fun.dns_name}"
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "CNAME"
  ttl          = "60"

  rrdatas = ["fm2.ramona.fun.dkim.fmhosted.com."]
}

resource "google_dns_record_set" "CNAME-fm3-_domainkey-ramona-fun" {
  name         = "fm3._domainkey.${google_dns_managed_zone.ramona-fun.dns_name}"
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "CNAME"
  ttl          = "60"

  rrdatas = ["fm3.ramona.fun.dkim.fmhosted.com."]
}

resource "google_dns_record_set" "TXT-ramona-fun" {
  name         = google_dns_managed_zone.ramona-fun.dns_name
  managed_zone = google_dns_managed_zone.ramona-fun.name
  ttl          = "60"
  type         = "TXT"

  rrdatas = ["\"v=spf1 include:spf.messagingengine.com ?all\""]
}

resource "google_dns_record_set" "TXT-_dmarc-ramona-fun" {
  name         = "_dmarc.${google_dns_managed_zone.ramona-fun.dns_name}"
  managed_zone = google_dns_managed_zone.ramona-fun.name

  type = "TXT"
  ttl  = "60"
  rrdatas = [
    "\"v=DMARC1; p=none; rua=mailto:dmarc@ramona.fun; ruf=mailto:dmarc@ramona.fun; fo=1\""
  ]
}

resource "dnsimple_zone_record" "CNAME--jellyfin-ramona-fun" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = "jellyfin"
  type      = "CNAME"
  value     = "cb380c2c50bc.sn.mynetname.net."
  ttl       = 60
}

resource "google_dns_record_set" "CNAME-jellyfin-ramona-fun" {
  name         = "jellyfin.${google_dns_managed_zone.ramona-fun.dns_name}"
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "CNAME"
  ttl          = "60"

  rrdatas = ["cb380c2c50bc.sn.mynetname.net."]
}
