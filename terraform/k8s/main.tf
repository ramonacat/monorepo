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

resource "helm_release" "rook-ceph-cluster" {
  name             = "rook-ceph-cluster"
  chart            = "rook-ceph-cluster"
  repository       = "https://charts.rook.io/release"
  namespace        = "rook-ceph-cluster"
  create_namespace = true
  version          = "v1.20.0"

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
            activeCount = 1
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

resource "hcloud_volume" "node" {
  for_each = toset(keys(var.control_plane_nodes))

  name      = each.value
  size      = 10
  server_id = module.k8s--control-plane-nodes[each.key].server_id
}

resource "hcloud_server_network" "node" {
  for_each = toset(keys(var.control_plane_nodes))

  server_id = module.k8s--control-plane-nodes[each.value].server_id
  subnet_id = var.subnet_id
  ip        = var.control_plane_nodes[each.value].private_ipv4
}

