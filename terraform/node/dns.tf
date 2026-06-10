resource "dnsimple_zone_record" "A--node" {
  zone_name = var.dns_zone_name
  name      = "${var.name}${var.dns_suffix}"
  type      = "A"
  value     = hcloud_server.node.ipv4_address
}

resource "dnsimple_zone_record" "AAAA--node" {
  zone_name = var.dns_zone_name
  name      = "${var.name}${var.dns_suffix}"
  type      = "AAAA"
  value     = hcloud_server.node.ipv6_address
}
