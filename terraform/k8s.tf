resource "hcloud_network_subnet" "k8s" {
  network_id   = hcloud_network.net.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.70.0.0/24"
}

module "k8s--darkmore" {
  source = "./k8s"

  name          = "darkmore"
  subnet_id     = hcloud_network_subnet.k8s.id
  dns_zone_name = dnsimple_zone.ramona-fun.name
  ssh_keys      = [hcloud_ssh_key.ramona.id, hcloud_ssh_key.ci.id]
  firewall_ids  = [hcloud_firewall.fw.id]
  control_plane_nodes = { for node in jsondecode(file("./k8s-nodes.json"))["darkmore"] : node.hostname => {
    tailscale_tags = split(" ", data.external.tailscale_tags.result[node.hostname]), private_ipv4 : node.ip
  } }
}

resource "tailscale_oauth_client" "kubernetes" {
  scopes = ["services", "devices:core", "auth_keys"]
  tags   = ["tag:k8s-operator"]
}

resource "kubernetes_namespace_v1" "kube-flannel" {
  metadata {
    name = "kube-flannel"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "flannel" {
  name       = "flannel"
  chart      = "flannel"
  repository = "https://flannel-io.github.io/flannel/"
  version    = "v0.28.5"
  namespace  = kubernetes_namespace_v1.kube-flannel.metadata[0].name

  set = [{
    name  = "podCidr",
    value = "10.72.0.0/16"
  }]
}

resource "helm_release" "tailscale" {
  name             = "tailscale"
  chart            = "tailscale-operator"
  repository       = "https://pkgs.tailscale.com/helmcharts"
  namespace        = "tailscale"
  create_namespace = true
  version          = "1.98.4"

  lifecycle {
    ignore_changes = [create_namespace]
  }

  set_sensitive = [
    {
      name  = "oauth.clientId"
      value = tailscale_oauth_client.kubernetes.id
    },
    {
      name  = "oauth.clientSecret"
      value = tailscale_oauth_client.kubernetes.key
    }
  ]
}

resource "helm_release" "kured" {
  name             = "kured"
  chart            = "kured"
  repository       = "https://kubereboot.github.io/charts"
  namespace        = "kured"
  create_namespace = true
  version          = "6.0.0"

  set = [
    {
      name  = "configuration.rebootCommand",
      value = "/run/current-system/sw/bin/systemctl reboot",
    }
  ]
}

resource "helm_release" "argo-cd" {
  name             = "argo-cd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = "argo-cd"
  create_namespace = true
  version          = "9.5.21"

  values = [yamlencode({
    global = { domain = "argo-cd.ibis-draconis.ts.net" },
    configs = {
      cm = { "accounts.terraform" = "apiKey" },
      rbac = {
        "policy.csv" = "g, terraform, role:admin"
      },
    },
    redis-ha = {
      enabled          = true,
      hardAntiAffinity = false,
      replicas         = 2,
      haproxy          = { hardAntiAffinity = false },
    },
    controller     = { replicas = 1 },
    server         = { replicas = 2 },
    repoServer     = { replicas = 2 },
    applicationSet = { replicas = 2 },
    ingress = {
      enabled          = true,
      hostname         = "argo-cd",
      ingressClassName = "tailscale",
      tls              = true,
      annotations = {
        "tailscale.com/proxy-group" = "tailscale-proxygroup"
      }
    }
  })]
}

resource "tls_private_key" "deploy--ramonacat-monorepo--argocd" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "ramonacat-monorepo--argocd" {
  title      = "ArgoCD"
  repository = github_repository.ramonacat-monorepo.name
  key        = tls_private_key.deploy--ramonacat-monorepo--argocd.public_key_openssh
  read_only  = true
}

resource "argocd_repository" "monorepo" {
  repo            = "git@github.com:ramonacat/monorepo.git"
  username        = "git"
  ssh_private_key = tls_private_key.deploy--ramonacat-monorepo--argocd.private_key_openssh
}

resource "argocd_application_set" "monorepo--apps" {
  metadata {
    name = "monorepo--apps"
  }

  spec {
    generator {
      git {
        repo_url = argocd_repository.monorepo.repo
        revision = "HEAD"

        directory {
          path = "kubernetes/darkmore/*"
        }
      }
    }

    template {
      metadata {
        name = "monorepo-darkmore-{{path.basename}}"
      }

      spec {
        source {
          repo_url        = argocd_repository.monorepo.repo
          target_revision = "HEAD"
          path            = "{{path}}"
        }

        destination {
          server    = "https://kubernetes.default.svc"
          namespace = "{{path.basename}}"
        }

        sync_policy {
          automated {
            prune     = true
            self_heal = true
          }

          sync_options = ["CreateNamespace=true"]
        }
      }
    }
  }
}
