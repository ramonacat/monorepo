terraform {
  backend "gcs" {
    bucket = "ramona-fun-tfstate"
    prefix = "terraform/state"
  }
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

variable "tailscale_oauth_client_secret" {
  sensitive = true
}

variable "tailscale_oauth_client_id" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "tailscale" {
  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
}

provider "google" {
  project = "ramona-infra"
  region  = "europe-west10"
}
