resource "helm_release" "grafana" {
  name             = "grafana"
  chart            = "grafana"
  repository       = "https://grafana-community.github.io/helm-charts"
  namespace        = "grafana"
  create_namespace = true
  version          = "12.7.3"

  values = [yamlencode({
    replicas = 2
    route = {
      main = {
        enabled    = true
        hostnames  = ["grafana.infrastructure.ramona.fun"]
        parentRefs = [{ name = "gateway-tailscale", namespace = "kgateway-system" }]
      }
    }
    podDisruptionBudget = {
      minAvailable = 1
    }
    serviceMonitor = { enabled = true }
    plugins        = ["yesoreyeram-infinity-datasource"]
    persistence = {
      enabled          = true
      storageClassName = "longhorn"
      size             = "192Mi"
      accessModes      = ["ReadWriteMany"]
    }
    sidecar = {
      dashboards  = { enabled = true }
      datasources = { enabled = true }
    }
    datasources = {
      "datasources.yaml" = {
        apiVersion        = 1
        deleteDatasources = [{ name = "prometheus" }]
      }
    }
    "grafana.ini" = {
      paths = {
        data         = "/var/lib/grafana/"
        logs         = "/var/log/grafana"
        plugins      = "/var/lib/grafana/plugins"
        provisioning = "/etc/grafana/provisioning"
      }
      analytics = {
        check_for_updates = true
      }
      log = {
        mode = "console"
      }
      server = {
        domain   = "{{ if (and .Values.ingress.enabled .Values.ingress.hosts) }}{{ tpl (.Values.ingress.hosts | first) . }}{{ else if (and .Values.route.main.enabled .Values.route.main.hostnames) }}{{ tpl (.Values.route.main.hostnames | first) . }}{{ else }}''{{ end }}"
        root_url = "https://grafana.infrastructure.ramona.fun/"
      }
      unified_storage = {
        index_path = "/var/lib/grafana-search/bleve"
      }
    }
  })]
}

