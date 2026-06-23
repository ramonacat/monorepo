resource "helm_release" "kube-prometheus-stack" {
  name             = "kube-prometheus-stack"
  chart            = "oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack"
  namespace        = "kube-prometheus-stack"
  create_namespace = true
  version          = "87.1.0"

  values = [yamlencode({
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

      # TODO this would be much easier with webhook_url_file, but it doesn't work with the operator
      # see: https://github.com/prometheus-operator/prometheus-operator/issues/7159
      config = {
        route = {
          receiver = "discord"
          group_by = ["..."]
          matchers = []
          routes = [
            { receiver = "null", matchers = ["alertname = Watchdog"] }
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
        replicas                                = 2
        retentionSize                           = "9900MiB"
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
            memory = "1536Mi"
          }
        }
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "longhorn"
              accessModes      = ["ReadWriteOnce"]
              resources        = { requests = { storage = "10Gi" } }
            }
          }
        }
      }
    }
  })]

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
  version          = "3.13.1"

  values = [yamlencode({
    replicas = 2
    args     = ["--kubelet-insecure-tls"]

    metrics        = { enabled = true }
    serviceMonitor = { enabled = true }
  })]
}
