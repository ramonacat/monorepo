terraform {
  required_providers {
    dnsimple = {
      source = "dnsimple/dnsimple"
    }
  }
}
resource "dnsimple_zone_record" "MX-1" {
  zone_name = var.zone_name
  name      = ""
  type      = "MX"
  value     = "in1-smtp.messagingengine.com."
  priority  = 10
  ttl       = 60
}

resource "dnsimple_zone_record" "MX-2" {
  zone_name = var.zone_name
  name      = ""
  type      = "MX"
  value     = "in2-smtp.messagingengine.com."
  priority  = 20
  ttl       = 60
}

resource "dnsimple_zone_record" "CNAME--fm1-_domainkey" {
  zone_name = var.zone_name
  name      = "fm1._domainkey"
  type      = "CNAME"
  value     = "fm1.${var.zone_name}.dkim.fmhosted.com."
  ttl       = 60
}

resource "dnsimple_zone_record" "CNAME--fm2-_domainkey" {
  zone_name = var.zone_name
  name      = "fm2._domainkey"
  type      = "CNAME"
  value     = "fm2.${var.zone_name}.dkim.fmhosted.com."
  ttl       = 60
}

resource "dnsimple_zone_record" "CNAME--fm3-_domainkey" {
  zone_name = var.zone_name
  name      = "fm3._domainkey"
  type      = "CNAME"
  value     = "fm3.${var.zone_name}.dkim.fmhosted.com."
  ttl       = 60
}

resource "dnsimple_zone_record" "TXT" {
  zone_name = var.zone_name
  name      = ""
  type      = "TXT"
  value     = "\"v=spf1 include:spf.messagingengine.com ?all\""
  ttl       = 60
}

resource "dnsimple_zone_record" "TXT--_dmarc" {
  zone_name = var.zone_name
  name      = "_dmarc"
  type      = "TXT"
  value     = "\"v=DMARC1; p=none;\""
  ttl       = 60
}
