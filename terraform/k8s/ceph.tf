resource "kubernetes_storage_class_v1" "local" {
  metadata {
    name = "local-storage"
  }

  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
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

resource "hcloud_volume" "node" {
  for_each = toset(keys(var.control_plane_nodes))

  name      = each.value
  size      = 10
  server_id = module.k8s--control-plane-nodes[each.key].server_id
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

resource "helm_release" "rook-ceph" {
  name             = "rook-ceph"
  chart            = "rook-ceph"
  repository       = "https://charts.rook.io/release"
  namespace        = "rook-ceph"
  create_namespace = true
  version          = "v1.20.1"

  values = [yamlencode({
  })]
}

resource "helm_release" "ceph-csi-drivers" {
  name             = "ceph-csi-drivers"
  chart            = "ceph-csi-drivers"
  repository       = "https://ceph.github.io/ceph-csi-operator"
  namespace        = helm_release.rook-ceph.namespace
  create_namespace = true
  version          = "v1.0.1"

  values = [yamlencode({
    operatorConfig = {
      namespace = "rook-ceph"
      driverSpecDefaults = {
        deployCsiAddons  = true
        imageSet         = { name = "rook-csi-operator-image-set-configmap" }
        nodePlugin       = { priorityClassName = "system-node-critical" }
        controllerPlugin = { priorityClassName = "system-cluster-critical" }
      }
    }
    drivers = {
      rbd    = { enabled = true, name = "${helm_release.rook-ceph.namespace}.rbd.csi.ceph.com", deployCsiAddons = true, snapshotPolicy = "volumeSnapshot" },
      cephfs = { enabled = true, name = "${helm_release.rook-ceph.namespace}.cephfs.csi.ceph.com", deployCsiAddons = true },
      nfs    = { enabled = true, name = "${helm_release.rook-ceph.namespace}.nfs.csi.ceph.com", deployCsiAddons = true },
      nvmeof = { enabled = false, name = "${helm_release.rook-ceph.namespace}.nvmeof.csi.ceph.com", deployCsiAddons = true },
    }
  })]
}


resource "helm_release" "rook-ceph-cluster" {
  name             = "rook-ceph-cluster"
  chart            = "rook-ceph-cluster"
  repository       = "https://charts.rook.io/release"
  namespace        = var.ceph_cluster_namespace
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
            "csi.storage.k8s.io/provisioner-secret-namespace"        = var.ceph_cluster_namespace
            "csi.storage.k8s.io/controller-expand-secret-name"       = "rook-csi-cephfs-provisioner"
            "csi.storage.k8s.io/controller-expand-secret-namespace"  = var.ceph_cluster_namespace
            "csi.storage.k8s.io/controller-publish-secret-name"      = "rook-csi-cephfs-provisioner"
            "csi.storage.k8s.io/controller-publish-secret-namespace" = var.ceph_cluster_namespace
            "csi.storage.k8s.io/node-stage-secret-name"              = "rook-csi-cephfs-node"
            "csi.storage.k8s.io/node-stage-secret-namespace"         = var.ceph_cluster_namespace
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
    cephFileSystemVolumeSnapshotClass = {
      enabled = true
    }
    cephBlockPoolsVolumeSnapshotClass = {
      enabled = true
    }
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
