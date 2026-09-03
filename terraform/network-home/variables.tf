variable "vault_pki" {
  type = string
}

variable "vault_role" {
  type = string
}

variable "cert_ca_root" {
  type = string
}

variable "cert_ca_hosts" {
  type = string
}

variable "cert_ca_internal" {
  type = string
}

variable "wifi_psk_iot" {
  type      = string
  sensitive = true
}

variable "wifi_psk_low_privilege" {
  type      = string
  sensitive = true
}
