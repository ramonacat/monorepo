resource "google_dns_managed_zone" "savin-gallery" {
  name        = "savin-gallery"
  dns_name    = "savin.gallery."
  description = "savin.gallery"
}

resource "google_dns_record_set" "A-savin-gallery" {
  name         = google_dns_managed_zone.savin-gallery.dns_name
  managed_zone = google_dns_managed_zone.savin-gallery.name
  type         = "A"
  ttl          = "60"

  rrdatas = [
    hcloud_server.crimson.ipv4_address
  ]
}
resource "google_dns_record_set" "AAAA-savin-gallery" {
  name         = google_dns_managed_zone.savin-gallery.dns_name
  managed_zone = google_dns_managed_zone.savin-gallery.name
  type         = "AAAA"
  ttl          = "60"

  rrdatas = [
    hcloud_server.crimson.ipv6_address
  ]
}
