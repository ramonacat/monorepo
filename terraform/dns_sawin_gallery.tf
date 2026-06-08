resource "ovh_domain_name_servers" "sawin-gallery" {
  domain = "sawin.gallery"
  servers { host = "ns1.dnsimple-edge.com" }
  servers { host = "ns2.dnsimple-edge.net" }
  servers { host = "ns3.dnsimple-edge.io" }
  servers { host = "ns4.dnsimple-edge.org" }
}
resource "dnsimple_zone" "sawin-gallery" {
  name   = "sawin.gallery"
  active = true
}

resource "dnsimple_zone_record" "A--sawin-gallery" {
  zone_name = dnsimple_zone.sawin-gallery.name
  name      = ""
  type      = "A"
  value     = hcloud_server.crimson.ipv4_address
  ttl       = 60
}

resource "dnsimple_zone_record" "AAAA--sawin-gallery" {
  zone_name = dnsimple_zone.sawin-gallery.name
  name      = ""
  type      = "AAAA"
  value     = hcloud_server.crimson.ipv6_address
  ttl       = 60
}
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
