resource "google_dns_managed_zone" "agares-info" {
  name        = "agares-info"
  dns_name    = "agares.info."
  description = "agares.info"
}

resource "google_dns_record_set" "MX-agares-info" {
  name         = google_dns_managed_zone.agares-info.dns_name
  type         = "MX"
  ttl          = "60"
  managed_zone = google_dns_managed_zone.agares-info.name

  rrdatas = [
    "1 alt1.aspmx.l.google.com.",
    "1 aspmx2.googlemail.com.",
    "1 aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 aspmx3.googlemail.com."
  ]
}

resource "google_dns_record_set" "TXT-agares-info" {
  name         = google_dns_managed_zone.agares-info.dns_name
  type         = "TXT"
  ttl          = "60"
  managed_zone = google_dns_managed_zone.agares-info.name

  rrdatas = [
    "\"v=spf1 include:_spf.google.com ~all\""
  ]
}
