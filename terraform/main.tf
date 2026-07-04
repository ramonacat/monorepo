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
    github = {
      source  = "integrations/github"
      version = ">= 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.2.0"
    }
    argocd = {
      source  = "argoproj-labs/argocd",
      version = ">= 7.15.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.3.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = ">= 2026.5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.52.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.10.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.9.0"
    }
  }
}

provider "hcloud" {
}

provider "tailscale" {
}

provider "dnsimple" {
}

provider "ovh" {
  endpoint = "ovh-eu"
}

provider "b2" {
}

provider "github" {
  owner = "ramonacat"
}

provider "kubernetes" {
}

provider "helm" {
}

provider "argocd" {
  server_addr = "argo-cd.infrastructure.ramona.fun"
}

provider "authentik" {
  url = "https://account.ramona.fun"
}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_access_key
  region     = "eu-central-1"
}

provider "vault" {
  address      = "https://vault.internal.ramona.fun"
  ca_cert_file = "../ca.crt"
}
