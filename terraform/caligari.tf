resource "google_dns_managed_zone" "ramona-fun" {
  name        = "ramona-fun"
  dns_name    = "ramona.fun."
  description = "ramona.fun"
}

resource "google_dns_record_set" "caligari-devices-ramona-fun" {
  name = "caligari.devices.${google_dns_managed_zone.ramona-fun.dns_name}"
  type = "A"
  ttl = "60"
  managed_zone = google_dns_managed_zone.ramona-fun.name

  rrdatas = ["85.10.199.138"]
}