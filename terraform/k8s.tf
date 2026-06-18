moved {
  from = tailscale_oauth_client.kubernetes
  to   = module.k8s--darkmore.tailscale_oauth_client.kubernetes
}

moved {
  from = kubernetes_namespace_v1.kube-flannel
  to   = module.k8s--darkmore.kubernetes_namespace_v1.kube-flannel
}

moved {
  from = helm_release.tailscale
  to   = module.k8s--darkmore.helm_release.tailscale
}

moved {
  from = helm_release.rook-ceph
  to   = module.k8s--darkmore.helm_release.rook-ceph
}

moved {
  from = helm_release.kured
  to   = module.k8s--darkmore.helm_release.kured
}

moved {
  from = helm_release.flannel
  to   = module.k8s--darkmore.helm_release.flannel
}

moved {
  from = helm_release.ceph-csi-drivers
  to   = module.k8s--darkmore.helm_release.ceph-csi-drivers
}

moved {
  from = module.k8s--darkmore.helm_release.grafana
  to   = helm_release.grafana
}

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
  control_plane_nodes = {
    for node in jsondecode(file("./k8s-nodes.json"))["darkmore"] : node.hostname =>
    {
      tailscale_tags = split(" ", data.external.tailscale_tags.result[node.hostname]),
      private_ipv4 : node.ip
    }
  }
  hcloud_token = var.kubernetes_darkmore_hcloud_token
}

resource "helm_release" "argo-cd" {
  name             = "argo-cd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = "argo-cd"
  create_namespace = true
  version          = "9.5.21"

  values = [yamlencode({
    global = {
      domain                   = "argo-cd.ibis-draconis.ts.net"
      addPrometheusAnnotations = true
    },
    configs = {
      cm = { "accounts.terraform" = "apiKey" },
      params = {
        "server.insecure" = true
      },
      rbac = {
        "policy.csv" = "g, terraform, role:admin"
      },
    },
    redis-ha = {
      enabled          = true,
      hardAntiAffinity = false,
      replicas         = 2,
      haproxy = {
        replicas         = 2,
        hardAntiAffinity = false
      },
    },
    controller = {
      replicas = 1,
      metrics = {
        enabled = true
      }
    },
    server = {
      replicas = 2
      ingress = {
        enabled          = true,
        ingressClassName = "tailscale",
        tls              = true,
        annotations = {
          "tailscale.com/proxy-group" = "service-ingress"
          "tailscale.com/tags"        = "tag:k8s,tag:k8s-service"
        }
      }
      metrics = {
        enabled = true
      }
    },
    repoServer = {
      replicas = 2
      metrics = {
        enabled = true
      }
    },
    applicationSet = {
      replicas = 2
      metrics = {
        enabled = true
      }
    },
  })]
}

resource "helm_release" "grafana" {
  name             = "grafana"
  chart            = "grafana"
  repository       = "https://grafana-community.github.io/helm-charts"
  namespace        = "grafana"
  create_namespace = true
  version          = "12.4.8"

  values = [yamlencode({
    replicas = 2
    ingress = {
      enabled          = true
      ingressClassName = "tailscale"
      annotations = {
        "tailscale.com/proxy-group" = "service-ingress"
        "tailscale.com/tags"        = "tag:k8s,tag:k8s-service"
      }
      hosts = ["grafana.ibis-draconis.ts.net"]
      tls   = [{ hosts = ["grafana.ibis-draconis.ts.net"] }]
    }
    persistence = {
      enabled          = true
      storageClassName = "ceph-filesystem"
      size             = "256Mi"
      accessModes      = ["ReadWriteMany"]
    }
    datasources = {
      "datasources.yaml" = {
        apiVersion = 1,
        datasources = [
          {
            name   = "prometheus"
            type   = "prometheus"
            url    = "http://prometheus-server.prometheus"
            access = "proxy"
          }
        ]
      }
    }
  })]
}
