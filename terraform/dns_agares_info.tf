resource "google_dns_managed_zone" "agares-info" {
  name        = "agares-info"
  dns_name    = "agares.info."
  description = "agares.info"
}

resource "google_dns_record_set" "MX-agares-info" {
  name         = google_dns_managed_zone.agares-info.dns_name
  managed_zone = google_dns_managed_zone.agares-info.name
  ttl          = "60"
  type         = "MX"

  rrdatas = [
    "10 in1-smtp.messagingengine.com.",
    "20 in2-smtp.messagingengine.com."
  ]
}

resource "google_dns_record_set" "CNAME-fm1-_domainkey-agares-info" {
  name         = "fm1._domainkey.${google_dns_managed_zone.agares-info.dns_name}"
  managed_zone = google_dns_managed_zone.agares-info.name
  type         = "CNAME"
  ttl          = "60"

  rrdatas = ["fm1.agares.info.dkim.fmhosted.com."]
}

resource "google_dns_record_set" "CNAME-fm2-_domainkey-agares-info" {
  name         = "fm2._domainkey.${google_dns_managed_zone.agares-info.dns_name}"
  managed_zone = google_dns_managed_zone.agares-info.name
  type         = "CNAME"
  ttl          = "60"

  rrdatas = ["fm2.agares.info.dkim.fmhosted.com."]
}

resource "google_dns_record_set" "CNAME-fm3-_domainkey-agares-info" {
  name         = "fm3._domainkey.${google_dns_managed_zone.agares-info.dns_name}"
  managed_zone = google_dns_managed_zone.agares-info.name
  type         = "CNAME"
  ttl          = "60"

  rrdatas = ["fm3.agares.info.dkim.fmhosted.com."]
}

resource "google_dns_record_set" "TXT-agares-info" {
  name         = google_dns_managed_zone.agares-info.dns_name
  managed_zone = google_dns_managed_zone.agares-info.name
  ttl          = "60"
  type         = "TXT"

  rrdatas = ["\"v=spf1 include:spf.messagingengine.com ?all\""]
}
