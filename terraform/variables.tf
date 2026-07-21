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

variable "rustfs_access_key_id" {
  type      = string
  sensitive = true
}

variable "rustfs_access_key" {
  type      = string
  sensitive = true
}
