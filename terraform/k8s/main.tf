terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.65.0"
    }
  }
}

// TODO move the helm charts into this module?
resource "kubernetes_storage_class_v1" "local" {
  metadata {
    name = "local-storage"
  }

  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "hcloud_placement_group" "nodes" {
  name = "${var.name}-nodes"
  type = "spread"
}

module "k8s--control-plane-nodes" {
  source   = "../node"
  for_each = toset(keys(var.control_plane_nodes))

  name               = each.value
  placement_group_id = hcloud_placement_group.nodes.id
  ssh_keys           = var.ssh_keys
  dns_zone_name      = var.dns_zone_name
  tailscale_tags     = var.control_plane_nodes[each.value].tailscale_tags
  firewall_ids       = var.firewall_ids
  server_type        = "cx33"
  before_node_update = { command = "kubectl", arguments = ["drain", "--delete-emptydir-data", "--ignore-daemonsets", each.value] }
  after_node_update  = { command = "kubectl", arguments = ["uncordon", each.value] }
}

resource "kubernetes_persistent_volume_v1" "local-mon" {
  for_each = toset(keys(var.control_plane_nodes))

  metadata {
    name = "local-${each.value}-mon"
  }

  spec {
    storage_class_name = kubernetes_storage_class_v1.local.metadata[0].name
    capacity = {
      "storage" : "10Gi"
    }
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    volume_mode                      = "Filesystem"

    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = [each.value]
          }
        }
      }
    }

    persistent_volume_source {
      local {
        path = "/var/ceph/mon/"
      }
    }
  }
}

resource "kubernetes_persistent_volume_v1" "local-osd" {
  for_each = toset(keys(var.control_plane_nodes))

  metadata {
    name = "local-${each.value}-osd"
  }

  spec {
    storage_class_name = kubernetes_storage_class_v1.local.metadata[0].name
    capacity = {
      "storage" : "${hcloud_volume.node[each.value].size}Gi"
    }
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    volume_mode                      = "Block"

    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = [each.value]
          }
        }
      }
    }

    persistent_volume_source {
      local {
        path = hcloud_volume.node[each.value].linux_device
      }
    }
  }
}

resource "hcloud_volume" "node" {
  for_each = toset(keys(var.control_plane_nodes))

  name      = each.value
  size      = 10
  server_id = module.k8s--control-plane-nodes[each.key].server_id
}

resource "helm_release" "rook-ceph-cluster" {
  name             = "rook-ceph-cluster"
  chart            = "rook-ceph-cluster"
  repository       = "https://charts.rook.io/release"
  namespace        = "rook-ceph-cluster"
  create_namespace = true
  version          = "v1.20.1"

  values = [yamlencode({
    cephClusterSpec = {
      mon = {
        count = 3
        volumeClaimTemplate = {
          spec = {
            storageClassName = kubernetes_storage_class_v1.local.metadata[0].name
            volumeMode       = "Filesystem",
            resources = {
              requests = {
                storage = "10Gi"
              }
            }
          }
        }
      }
      storage = {
        useAllNodes   = false
        useAllDevices = false

        storageClassDeviceSets = [
          {
            name      = "set1",
            count     = 3,
            portable  = false,
            encrypted = false,
            volumeClaimTemplates = [
              {
                metadata = { name = "data" }
                spec = {
                  resources = {
                    requests = {
                      storage = "10Gi"
                    },
                  }
                  storageClassName = kubernetes_storage_class_v1.local.metadata[0].name,
                  volumeMode       = "Block",
                  accessModes      = ["ReadWriteOnce"]
                }
              }
            ]
          }
        ]
      }
      resources = {
        mgr = {
          requests = {
            cpu    = "50m"
            memory = "256Mi"
          }
        }
        mon = {
          requests = {
            cpu    = "50m"
            memory = "256Mi"
          }
        }
        osd = {
          requests = {
            cpu    = "50m"
            memory = "256Mi"
          }
        }
        prepareosd = {
          requests = {
            cpu = "50m"
          }
        }
        mgr-sidecar = {
          requests = {
            cpu = "50m"
          }
        }
        crashcollector = {
          requests = {
            cpu = "50m"
          }
        }
        logcollector = {
          requests = {
            cpu = "50m"
          }
        }
        cleanup = {
          requests = {
            cpu    = "50m"
            memory = "256Mi"
          }
        }
        exporter = {
          requests = {
            cpu = "50m"
          }
        }
        cmd-reporter = {
          requests = {
            cpu = "50m"
          }
        }
      }
      dashboard = {
        ssl = false
      }
    }
    cephFileSystems = [
      {
        name = "ceph-filesystem",
        spec = {
          metadataPool = {
            replicated = {
              size = 3
            }
          }
          dataPools = [
            {
              failureDomain = "host",
              replicated = {
                size = 3
              },
              name = "data0"
            }
          ]
          metadataServer = {
            activeCount   = 1
            activeStandby = true
            resources = {
              requests = {
                cpu    = "50m",
                memory = "512Mi"
              }
            }
          }
        }
        storageClass = {
          enabled = true
          name    = "ceph-filesystem"
          parameters = {
            "csi.storage.k8s.io/provisioner-secret-name"             = "rook-csi-cephfs-provisioner"
            "csi.storage.k8s.io/provisioner-secret-namespace"        = "rook-ceph-cluster"
            "csi.storage.k8s.io/controller-expand-secret-name"       = "rook-csi-cephfs-provisioner"
            "csi.storage.k8s.io/controller-expand-secret-namespace"  = "rook-ceph-cluster"
            "csi.storage.k8s.io/controller-publish-secret-name"      = "rook-csi-cephfs-provisioner"
            "csi.storage.k8s.io/controller-publish-secret-namespace" = "rook-ceph-cluster"
            "csi.storage.k8s.io/node-stage-secret-name"              = "rook-csi-cephfs-node"
            "csi.storage.k8s.io/node-stage-secret-namespace"         = "rook-ceph-cluster"
          }
        }
      }
    ]
    cephObjectStores = [
      {
        name = "ceph-objectstore",
        spec = {
          gateway = {
            port = 80
            resources = {
              requests = {
                cpu    = "50m",
                memory = "512Mi"
              }
            }
          }
        }
        storageClass = {
          enabled = true
          name    = "ceph-bucket"
        }
      }
    ]
    ingress = {
      dashboard = {
        annotations = {
          "tailscale.com/proxy-group" = "service-ingress"
          "tailscale.com/tags"        = "tag:k8s,tag:k8s-service"
        },
        host = {
          name = "ceph-${var.name}.ibis-draconis.ts.net"
        },
        tls              = [{ hosts = ["ceph-${var.name}.ibis-draconis.ts.net"] }],
        ingressClassName = "tailscale"
      }
    }
  })]
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  chart            = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  namespace        = "prometheus"
  create_namespace = true
  version          = "29.12.0"

  values = [yamlencode({
    server = {
      persistentVolume = {
        size = "1Gi"
      }
      replicaCount = 2
      statefulSet = {
        enabled = true
      }
    }
  })]
}

resource "helm_release" "grafana" {
  name             = "grafana"
  chart            = "grafana"
  repository       = "https://grafana-community.github.io/helm-charts"
  namespace        = "grafana"
  create_namespace = true
  version          = "12.4.6"

  values = [yamlencode({
    replicas = 2
    ingress = {
      enabled = true
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
      prometheus = {
        name   = "prometheus"
        type   = "prometheus"
        url    = "http://prometheus-prometheus-server"
        access = "proxy"
      }
    }
  })]
}

resource "hcloud_server_network" "node" {
  for_each = toset(keys(var.control_plane_nodes))

  server_id = module.k8s--control-plane-nodes[each.value].server_id
  subnet_id = var.subnet_id
  ip        = var.control_plane_nodes[each.value].private_ipv4
}

