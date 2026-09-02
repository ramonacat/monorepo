resource "helm_release" "kube-prometheus-stack" {
  name             = "kube-prometheus-stack"
  chart            = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  namespace        = "kube-prometheus-stack"
  create_namespace = true
  version          = "88.6.2"

  values = [yamlencode({
    // TODO alertmanager should be a separate deployment, outside of the module, as there's really only one needed (not one on every cluster)
    alertmanager = {
      alertmanagerSpec = {
        replicas  = 2
        logFormat = "json"
      }
      route = {
        main = {
          enabled    = true
          hostnames  = ["alertmanager.infrastructure.ramona.fun"]
          parentRefs = [{ name = "gateway-tailscale", namespace = "kgateway-system" }]
        }
      }

      config = {
        route = {
          receiver = "discord"
          group_by = ["..."]
          matchers = []
          routes = [
            {
              receiver = "null",
              matchers = [
                "severity=~\"none|info\"",
              ]
            },
            {
              receiver   = "discord",
              group_wait = "15m",
              matchers = [
                "severity=warning"
              ]
            }
          ]
        }
        receivers = [
          { name = "discord", discord_configs = [{}] },
          { name = "null" }
        ]
      }
    }
    grafana = {
      enabled = false

      namespaceOverride      = "grafana"
      forceDeployDatasources = var.create_grafana_dashboards
      forceDeployDashboards  = var.create_grafana_dashboards
    }
    prometheusOperator = {
      logFormat = "json"
    }
    prometheus = {
      route = {
        main = {
          enabled    = true
          hostnames  = ["prometheus.infrastructure.ramona.fun"]
          parentRefs = [{ name = "gateway-tailscale", namespace = "kgateway-system" }]
        }
      }
      prometheusSpec = {
        // one replica is fine, the container will just get rescheduled when it needs to, and the storage is replicated anyway
        replicas                                = 1
        cleanPrometheusOperatorObjectNames      = true
        retentionSize                           = "18GB"
        podMonitorSelectorNilUsesHelmValues     = false
        probeSelectorNilUsesHelmValues          = false
        ruleSelectorNilUsesHelmValues           = false
        scrapeConfigSelectorNilUsesHelmValues   = false
        serviceMonitorSelectorNilUsesHelmValues = false
        logFormat                               = "json"
        resources = {
          requests = {
            memory = "1024Mi"
          }
          limits = {
            memory = "2048Mi"
            cpu    = "1000m"
          }
        }
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "hcloud-volumes"
              accessModes      = ["ReadWriteOnce"]
              resources        = { requests = { storage = "20Gi" } }
            }
          }
        }
      }
    }
    kubeEtcd = {
      endpoints = [for node in var.nodes : node.private_ipv4 if node.is_control_plane]
    }
    kubeScheduler = {
      endpoints = [for node in var.nodes : node.private_ipv4 if node.is_control_plane]
    }
    kubeControllerManager = {
      endpoints = [for node in var.nodes : node.private_ipv4 if node.is_control_plane]
    }
    kubeProxy = {
      endpoints = [for node in var.nodes : node.private_ipv4]
    }
    defaultRules = {
      disabled = {
        // this rule is way too eager and starts complaining at the slightest touch of swap
        NodeMemoryMajorPagesFaults = true
      }
    }
  })]

  # TODO this would be much easier with webhook_url_file, but it doesn't work with the operator
  # see: https://github.com/prometheus-operator/prometheus-operator/issues/7159
  # perhaps just inject a secret from vault?
  set_sensitive = [{
    name  = "alertmanager.config.receivers[0].discord_configs[0].webhook_url"
    value = var.discord_webhook
  }]
}

resource "helm_release" "metrics-api" {
  name             = "metrics-api"
  chart            = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  namespace        = "kube-system"
  create_namespace = true
  version          = "3.14.0"

  values = [yamlencode({
    replicas = 2
    args     = ["--kubelet-insecure-tls"]

    metrics        = { enabled = true }
    serviceMonitor = { enabled = true }
  })]
}

resource "helm_release" "prometheus-systemd-exporter" {
  name             = "prometheus-systemd-exporter"
  chart            = "prometheus-systemd-exporter"
  repository       = "https://prometheus-community.github.io/helm-charts"
  namespace        = "prometheus-systemd-exporter"
  create_namespace = true
  version          = "0.5.2"

  values = [yamlencode({
    prometheus = {
      monitor = { enabled = true }
      rules   = { enabled = true }
    }
    config = {
      systemd = {
        collector = {
          unitInclude = [".+"]
        }
      }
    }
  })]
}
