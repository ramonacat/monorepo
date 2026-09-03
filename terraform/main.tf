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
    grafana = {
      source  = "grafana/grafana"
      version = ">= 4.40.0"
    }
    routeros = {
      source = "terraform-routeros/routeros"
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

provider "b2" {
  alias              = "eu"
  application_key_id = var.b2_eu_access_key_id
  application_key    = var.b2_eu_access_key
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
  address     = "https://vault.internal.ramona.fun"
  ca_cert_dir = "../certificates/"
}

provider "grafana" {
  url = "https://grafana.infrastructure.ramona.fun"
}

module "network-home" {
  source = "./network-home"

  cert_ca_root           = vault_pki_secret_backend_root_cert.a.certificate
  cert_ca_internal       = module.pki-internal.certificate
  cert_ca_hosts          = module.pki-hosts.certificate
  vault_pki              = module.pki-hosts.mount_path
  vault_role             = vault_pki_secret_backend_role.hosts.name
  wifi_psk_iot           = var.wifi_psk_iot
  wifi_psk_low_privilege = var.wifi_psk_low_privilege
}
