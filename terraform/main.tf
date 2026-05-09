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

locals {
  gcs_project_id = "ramona-infra"
}

provider "google" {
  project               = local.gcs_project_id
  region                = "europe-west10"
  user_project_override = true
  billing_project       = local.gcs_project_id
}

resource "google_project_service" "billing" {
  project = local.gcs_project_id
  service = "billingbudgets.googleapis.com"
}
