variable "caligari_ip_address" {
  type    = string
  default = "85.10.199.138"
}

variable "blackwood_ip_address" {
  type    = string
  default = "37.27.125.251"
}

resource "google_dns_managed_zone" "ramona-fun" {
  name        = "ramona-fun"
  dns_name    = "ramona.fun."
  description = "ramona.fun"
}

resource "google_dns_record_set" "caligari-devices-ramona-fun" {
  name         = "caligari.devices.${google_dns_managed_zone.ramona-fun.dns_name}"
  type         = "A"
  ttl          = "60"
  managed_zone = google_dns_managed_zone.ramona-fun.name

  rrdatas = [var.caligari_ip_address]
}

resource "google_dns_record_set" "blackwood-devices-ramona-fun" {
  name         = "blackwood.devices.${google_dns_managed_zone.ramona-fun.dns_name}"
  type         = "A"
  ttl          = "60"
  managed_zone = google_dns_managed_zone.ramona-fun.name

  rrdatas = [var.blackwood_ip_address]
}


resource "google_dns_record_set" "minecraft-services-ramona-fun" {
  name         = "minecraft.services.${google_dns_managed_zone.ramona-fun.dns_name}"
  type         = "A"
  ttl          = "60"
  managed_zone = google_dns_managed_zone.ramona-fun.name

  rrdatas = [var.blackwood_ip_address]
}

resource "google_dns_record_set" "ramona-fun" {
  name         = google_dns_managed_zone.ramona-fun.dns_name
  managed_zone = google_dns_managed_zone.ramona-fun.name

  type    = "A"
  rrdatas = [var.blackwood_ip_address]
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
