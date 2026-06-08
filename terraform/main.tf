terraform {
  backend "s3" {
    bucket = "ramona-fun-tfstate"
    key    = "tfstate"
    region = "us-west-002"
    endpoints = {
      s3 = "https://s3.us-west-002.backblazeb2.com"
    }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }

  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
    dnsimple = {
      source = "dnsimple/dnsimple"
    }
    ovh = {
      source = "ovh/ovh"
    }
    b2 = {
      source = "Backblaze/b2"
    }
  }
}

provider "hcloud" {
}

provider "tailscale" {
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

provider "dnsimple" {
}

provider "ovh" {
  endpoint = "ovh-eu"
}

resource "google_project_service" "billing" {
  project = local.gcs_project_id
  service = "billingbudgets.googleapis.com"
}

provider "b2" {
}
