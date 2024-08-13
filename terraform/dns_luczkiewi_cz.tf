resource "google_dns_managed_zone" "luczkiewi-cz" {
  name        = "luczkiewi-cz"
  dns_name    = "luczkiewi.cz."
  description = "luczkiewi.cz"
}

resource "google_dns_record_set" "MX-luczkiewi-cz" {
  name         = google_dns_managed_zone.luczkiewi-cz.dns_name
  managed_zone = google_dns_managed_zone.luczkiewi-cz.name
  ttl          = "60"
  type         = "MX"

  rrdatas = [
    "10 in1-smtp.messagingengine.com.",
    "20 in2-smtp.messagingengine.com."
  ]
}

resource "google_dns_record_set" "CNAME-fm1-_domainkey-luczkiewi-cz" {
  name         = "fm1._domainkey.${google_dns_managed_zone.luczkiewi-cz.dns_name}"
  managed_zone = google_dns_managed_zone.luczkiewi-cz.name
  type         = "CNAME"
  ttl          = "60"

  rrdatas = ["fm1.luczkiewi.cz.dkim.fmhosted.com."]
}

resource "google_dns_record_set" "CNAME-fm2-_domainkey-luczkiewi-cz" {
  name         = "fm2._domainkey.${google_dns_managed_zone.luczkiewi-cz.dns_name}"
  managed_zone = google_dns_managed_zone.luczkiewi-cz.name
  type         = "CNAME"
  ttl          = "60"

  rrdatas = ["fm2.luczkiewi.cz.dkim.fmhosted.com."]
}

resource "google_dns_record_set" "CNAME-fm3-_domainkey-luczkiewi-cz" {
  name         = "fm3._domainkey.${google_dns_managed_zone.luczkiewi-cz.dns_name}"
  managed_zone = google_dns_managed_zone.luczkiewi-cz.name
  type         = "CNAME"
  ttl          = "60"

  rrdatas = ["fm3.luczkiewi.cz.dkim.fmhosted.com."]
}

resource "google_dns_record_set" "TXT-luczkiewi-cz" {
  name         = google_dns_managed_zone.luczkiewi-cz.dns_name
  managed_zone = google_dns_managed_zone.luczkiewi-cz.name
  ttl          = "60"
  type         = "TXT"

  rrdatas = ["\"v=spf1 include:spf.messagingengine.com ?all\""]
}
