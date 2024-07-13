variable "caligari_ip_address" {
    type = string
    default = "85.10.199.138"
}

variable "blackwood_ip_address" {
    type = string
    default = "37.27.125.251"
}

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

  rrdatas = [ var.caligari_ip_address ]
}

resource "google_dns_record_set" "blackwood-devices-ramona-fun" {
  name = "blackwood.devices.${google_dns_managed_zone.ramona-fun.dns_name}"
  type = "A"
  ttl = "60"
  managed_zone = google_dns_managed_zone.ramona-fun.name

  rrdatas = [ var.blackwood_ip_address ]
}

resource "google_dns_record_set" "ramona-fun" {
  name = "${google_dns_managed_zone.ramona-fun.dns_name}"
  managed_zone = google_dns_managed_zone.ramona-fun.name

  type = "A"
  rrdatas = [ var.blackwood_ip_address ]
}
