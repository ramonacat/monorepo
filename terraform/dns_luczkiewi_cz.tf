resource "google_dns_managed_zone" "luczkiewi-cz" {
  name        = "luczkiewi-cz"
  dns_name    = "luczkiewi.cz."
  description = "luczkiewi.cz"
}

resource "google_dns_record_set" "MX-luczkiewi-cz" {
  name         = google_dns_managed_zone.luczkiewi-cz.dns_name
  type         = "MX"
  ttl          = "60"
  managed_zone = google_dns_managed_zone.luczkiewi-cz.name

  rrdatas = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com.",
    "10 alt4.aspmx.l.google.com.",
  ]
}

resource "google_dns_record_set" "TXT-luczkiewi-cz" {
  name         = google_dns_managed_zone.luczkiewi-cz.dns_name
  type         = "TXT"
  ttl          = "60"
  managed_zone = google_dns_managed_zone.luczkiewi-cz.name

  rrdatas = [
    "v=spf1 include:_spf.google.com ~all"
  ]
}
