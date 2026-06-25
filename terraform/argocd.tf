resource "tls_private_key" "deploy--ramonacat-monorepo--argocd" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "ramonacat-monorepo--argocd" {
  title      = "ArgoCD"
  repository = github_repository.ramonacat-monorepo.name
  key        = tls_private_key.deploy--ramonacat-monorepo--argocd.public_key_openssh
  read_only  = true
}

resource "argocd_repository" "monorepo" {
  repo            = "git@github.com:ramonacat/monorepo.git"
  username        = "git"
  ssh_private_key = tls_private_key.deploy--ramonacat-monorepo--argocd.private_key_openssh
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

          sync_options = ["CreateNamespace=true"]
        }
      }
    }
  }
}
