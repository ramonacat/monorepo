terraform {
  backend "s3" {
    bucket  = "tfstate"
    key     = "state/terraform.tfstate"
    region  = "us-east-1"
    encrypt = false

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true

    shared_credentials_files = ["/home/ramona/minio-terraform-state"]

    endpoints = {
      s3 = "http://thornton:9000/"
    }
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
