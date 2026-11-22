resource "vault_pki_secret_backend_cert" "christanti--argo-cd" {
  backend     = module.pki-christanti.mount_path
  name        = vault_pki_secret_backend_role.christanti-masters.name
  common_name = "system:masters"
  ttl         = 2592000 # 30 days-ish
  auto_renew  = true
}

resource "argocd_cluster" "christanti" {
  # TODO this should be an anycast IP for all the nodes
  server = "https://10.64.0.10:6443"
  name   = "christanti"

  config {
    tls_client_config {
      ca_data   = vault_pki_secret_backend_cert.christanti--argo-cd.ca_chain
      cert_data = vault_pki_secret_backend_cert.christanti--argo-cd.certificate
      key_data  = vault_pki_secret_backend_cert.christanti--argo-cd.private_key
    }
  }
}

resource "argocd_application_set" "monorepo--christanti--apps" {
  metadata {
    name = "monorepo--christanti--apps"
  }

  spec {
    generator {
      git {
        repo_url = argocd_repository.monorepo.repo
        revision = "HEAD"

        directory {
          path = "kubernetes/christanti/*"
        }
      }
    }

    template {
      metadata {
        name = "monorepo-christanti-{{path.basename}}"
        annotations = {
          # workaround for gateway resources being out of sync
          # https://github.com/argoproj/argo-cd/issues/22151#issuecomment-3804230010
          "argocd.argoproj.io/compare-options" = "ServerSideDiff=true,IncludeMutationWebhook=true"
        }
      }

      spec {
        source {
          repo_url        = argocd_repository.monorepo.repo
          target_revision = "HEAD"
          path            = "{{path}}"
        }

        ignore_difference {
          kind                = "Service"
          jq_path_expressions = ["select(.metadata.annotations | has(\"tailscale.com/proxy-group\")).spec.externalName"]
        }

        destination {
          name      = "christanti"
          namespace = "{{path.basename}}"
        }

        sync_policy {
          automated {
            prune     = true
            self_heal = true
          }

          sync_options = ["CreateNamespace=true", "ServerSideApply=true"]
        }
      }
    }
  }
}
