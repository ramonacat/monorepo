resource "google_dns_managed_zone" "sawin-gallery" {
  name        = "sawin-gallery"
  dns_name    = "sawin.gallery."
  description = "sawin.gallery"
}

resource "google_dns_record_set" "A-sawin-gallery" {
  name         = google_dns_managed_zone.sawin-gallery.dns_name
  managed_zone = google_dns_managed_zone.sawin-gallery.name
  type         = "A"
  ttl          = "60"

  rrdatas = [
    hcloud_server.crimson.ipv4_address
  ]
}
resource "google_dns_record_set" "AAAA-sawin-gallery" {
  name         = google_dns_managed_zone.sawin-gallery.dns_name
  managed_zone = google_dns_managed_zone.sawin-gallery.name
  type         = "AAAA"
  ttl          = "60"

  rrdatas = [
    hcloud_server.crimson.ipv6_address
  ]
}
