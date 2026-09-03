variable "kubernetes_darkmore_hcloud_token" {
  type      = string
  sensitive = true
}

variable "kubernetes_darkmore_dnsimple_token" {
  type      = string
  sensitive = true
}

variable "kubernetes_darkmore_discord_webhook" {
  type      = string
  sensitive = true
}

variable "aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "b2_eu_access_key_id" {
  type      = string
  sensitive = true
}

variable "b2_eu_access_key" {
  type      = string
  sensitive = true
}

variable "wifi_psk_iot" {
  type      = string
  sensitive = true
}

variable "wifi_psk_low_privilege" {
  type      = string
  sensitive = true
}
