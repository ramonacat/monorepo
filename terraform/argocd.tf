resource "argocd_repository" "monorepo" {
  repo            = "ssh://git@code.ramona.fun/ramona/monorepo.git"
  username        = "git"
  ssh_private_key = data.vault_kv_secret_v2.argo-cd-forgejo.data.ssh_key
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

        ignore_difference {
          kind                = "Service"
          jq_path_expressions = ["select(.metadata.annotations | has(\"tailscale.com/proxy-group\")).spec.externalName"]
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

          sync_options = ["CreateNamespace=true", "ServerSideApply=true"]
        }
      }
    }
  }
}

data "vault_kv_secret_v2" "argo-cd-forgejo" {
  mount = "secrets/kubernetes/darkmore"
  name  = "argo-cd/forgejo"
}

resource "argocd_repository" "monorepo-secret" {
  repo            = "ssh://git@code.ramona.fun/ramona/monorepo-secret.git"
  username        = "git"
  ssh_private_key = data.vault_kv_secret_v2.argo-cd-forgejo.data.ssh_key
}

resource "argocd_application_set" "monorepo-secret--apps" {
  metadata {
    name = "monorepo-secret--apps"
  }

  spec {
    generator {
      git {
        repo_url = argocd_repository.monorepo-secret.repo
        revision = "HEAD"

        directory {
          path = "kubernetes/darkmore/*"
        }
      }
    }

    template {
      metadata {
        name = "monorepo-secret-darkmore-{{path.basename}}"
      }

      spec {
        source {
          repo_url        = argocd_repository.monorepo-secret.repo
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

          sync_options = ["CreateNamespace=true", "ServerSideApply=true"]
        }
      }
    }
  }
}
