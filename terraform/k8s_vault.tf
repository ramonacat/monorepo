resource "aws_kms_key" "vault" {
}

resource "aws_iam_user" "vault" {
  name = "vault"
}

resource "aws_iam_group" "vault-server" {
  name = "vault-server"
}


data "aws_iam_policy_document" "vault-seal-access" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_group_membership" "vault-server" {
  name  = "vault-server"
  group = aws_iam_group.vault-server.name
  users = [
    aws_iam_user.vault.name
  ]
}

resource "aws_iam_group_policy" "vault-seal-access" {
  policy = data.aws_iam_policy_document.vault-seal-access.json
  group  = aws_iam_group.vault-server.name
}

resource "aws_iam_access_key" "vault" {
  user = aws_iam_user.vault.name
}

resource "kubernetes_namespace_v1" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_secret_v1" "vault" {
  metadata {
    name      = "aws"
    namespace = kubernetes_namespace_v1.vault.metadata[0].name
  }

  data = {
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.vault.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.vault.secret
  }
}

resource "helm_release" "vault" {
  name       = "vault"
  chart      = "vault"
  repository = "https://helm.releases.hashicorp.com"
  namespace  = kubernetes_namespace_v1.vault.metadata[0].name
  version    = "0.33.0"

  values = [yamlencode({
    global = {
      serverTelemetry = { prometheusOperator = true }
    }
    injector = {
      replicas = 2
      metrics  = { enabled = true }
      agentDefaults = {
        cpuRequest = "50mi"
      }
      logFormat = "json"
    }
    server = {
      extraSecretEnvironmentVars = [
        { envName = "AWS_ACCESS_KEY_ID", secretName = kubernetes_secret_v1.vault.metadata[0].name, secretKey = "AWS_ACCESS_KEY_ID" },
        { envName = "AWS_SECRET_ACCESS_KEY", secretName = kubernetes_secret_v1.vault.metadata[0].name, secretKey = "AWS_SECRET_ACCESS_KEY" },
      ]
      logFormat = "json"
      # TODO this isn't actually supported in 0.33.0, but should appear in the next version (https://github.com/hashicorp/vault-helm/pull/1142)
      httproute = {
        enabled    = true
        hostnames  = ["vault.infrastructure.ramona.fun"]
        parentRefs = [{ name = "gateway-tailscale", namespace = "kgateway-system" }]
      }
      dataStorage = {
        size = "128Mi"
      }
      ha = {
        enabled = true
        raft = {
          enabled = true
          config  = <<-EOT
              ui = true

              listener "tcp" {
                tls_disable = 1
                address = "[::]:8200"
                cluster_address = "[::]:8201"
                # Enable unauthenticated metrics access (necessary for Prometheus Operator)
                telemetry {
                  unauthenticated_metrics_access = "true"
                }
              }

              storage "raft" {
                path = "/vault/data"
              }

              service_registration "kubernetes" {}

              seal "awskms" {
                region = "eu-central-1"
                kms_key_id = "${aws_kms_key.vault.key_id}"
              }
            EOT
        }
      }
    }
    serverTelemetry = {
      serviceMonitor  = { enabled = true }
      prometheusRules = { enabled = true }
    }
  })]
}

