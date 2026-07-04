variable "hostname" {
  type = string
}

variable "tailscale_tags" {
  type = list(string)
}

variable "vault_pki" {
  type = string
}

variable "vault_role" {
  type = string
}
