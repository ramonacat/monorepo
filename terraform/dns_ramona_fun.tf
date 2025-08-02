variable "hallewell_tailscale_ip_address" {
  type    = string
  default = "100.109.240.138"
}

resource "google_dns_managed_zone" "ramona-fun" {
  name        = "ramona-fun"
  dns_name    = "ramona.fun."
  description = "ramona.fun"
}

resource "google_dns_record_set" "ras2-services-ramona-fun" {
  name         = "ras2.services.${google_dns_managed_zone.ramona-fun.dns_name}"
  type         = "A"
  ttl          = "60"
  managed_zone = google_dns_managed_zone.ramona-fun.name

  rrdatas = [var.hallewell_tailscale_ip_address]
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

resource "google_dns_record_set" "AAAA-ramona-fun" {
  name         = google_dns_managed_zone.ramona-fun.dns_name
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "AAAA"
  ttl          = "60"

  rrdatas = [
    hcloud_server.crimson.ipv6_address
  ]
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

resource "google_dns_record_set" "AAAA-crimson-devices-ramona-fun" {
  name         = "crimson.devices.${google_dns_managed_zone.ramona-fun.dns_name}"
  managed_zone = google_dns_managed_zone.ramona-fun.name
  type         = "AAAA"
  ttl          = "60"

  rrdatas = [
    hcloud_server.crimson.ipv6_address
  ]
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
