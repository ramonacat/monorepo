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
      s3 = "http://hallewell:9000/"
    }
  }
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "google" {
  project = "ramona-infra"
  region  = "europe-west10"
}
