resource "routeros_ip_service" "scarletwound-api" {
  provider = routeros.router-scarletwound
  numbers  = "api"
  port     = 8728
  disabled = true
}

resource "routeros_ip_service" "scarletwound-ftp" {
  provider = routeros.router-scarletwound
  numbers  = "ftp"
  port     = 21
  disabled = true
}

resource "routeros_ip_service" "scarletwound-ssh" {
  provider = routeros.router-scarletwound
  numbers  = "ssh"
  port     = 22
  disabled = true
}

resource "routeros_ip_service" "scarletwound-telnet" {
  provider = routeros.router-scarletwound
  numbers  = "telnet"
  port     = 23
  disabled = true
}

resource "routeros_ip_service" "scarletwound-winbox" {
  provider = routeros.router-scarletwound
  numbers  = "winbox"
  port     = 8291
}

resource "routeros_ip_service" "scarletwound-www" {
  provider = routeros.router-scarletwound
  numbers  = "www"
  port     = 80
}

resource "routeros_ip_service" "scarletwound-www-ssl" {
  provider    = routeros.router-scarletwound
  disabled    = false
  port        = 443
  numbers     = "www-ssl"
  certificate = routeros_system_certificate.scarletwound-ssl.name
}

resource "routeros_ip_service" "scarletwound-api-ssl" {
  provider    = routeros.router-scarletwound
  disabled    = false
  port        = 8729
  numbers     = "api-ssl"
  certificate = routeros_system_certificate.scarletwound-ssl.name
}
