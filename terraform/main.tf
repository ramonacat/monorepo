terraform {
  required_version = ">= 1.15.5"
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
    google = {
      source  = "google"
      version = ">= 7.35.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.65.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = ">= 0.29.2"
    }
    dnsimple = {
      source  = "dnsimple/dnsimple"
      version = ">= 2.1.2"
    }
    ovh = {
      source  = "ovh/ovh"
      version = ">= 2.13.1"
    }
    b2 = {
      source  = "Backblaze/b2"
      version = ">= 0.12.1"
    }
    external = {
      source  = "external"
      version = ">= 2.4.0"
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
