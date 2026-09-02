terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

provider "routeros" {
  hosturl        = "https://10.32.0.1/"
  username       = "terraform"
  ca_certificate = "../certificates/ca-hosts.crt"
  alias          = "router-scarletwound"
}
