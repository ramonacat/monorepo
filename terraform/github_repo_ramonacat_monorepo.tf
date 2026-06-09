resource "github_repository" "ramonacat-monorepo" {
  name        = "monorepo"
  visibility  = "public"
  description = "This is a monorepo that contains most of my apps and computer configurations."

  allow_merge_commit = true
  allow_rebase_merge = true
  allow_squash_merge = true

  allow_auto_merge = true

  has_issues   = true
  has_projects = false
  has_wiki     = false
}

resource "github_branch" "ramonacat-monorepo--main" {
  repository = github_repository.ramonacat-monorepo.name
  branch     = "main"
}

resource "github_branch_default" "ramonacat-monorepo--main" {
  repository = github_repository.ramonacat-monorepo.name
  branch     = github_branch.ramonacat-monorepo--main.branch
}

resource "github_actions_repository_permissions" "ramonacat-monorepo" {
  repository      = github_repository.ramonacat-monorepo.name
  allowed_actions = "all"
}

resource "github_branch_protection" "ramonacat-monorepo--main" {
  repository_id = github_repository.ramonacat-monorepo.node_id
  pattern       = "main"

  required_status_checks {
    contexts = ["build", "flake-check", "upload-coverage", "terraform"]
  }
}
