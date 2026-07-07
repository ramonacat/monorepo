resource "github_repository" "ramonacat-monorepo-secret" {
  name        = "monorepo-secret"
  visibility  = "private"
  description = "If you have access to this, you know what kinds of things are here. If you don't and you know me, you probably have a general idea."

  allow_merge_commit = true
  allow_rebase_merge = false
  allow_squash_merge = false

  allow_auto_merge = true

  has_issues   = true
  has_projects = false
  has_wiki     = false
}

resource "github_branch" "ramonacat-monorepo-secret--main" {
  repository = github_repository.ramonacat-monorepo-secret.name
  branch     = "main"
}

resource "github_branch_default" "ramonacat-monorepo-secret--main" {
  repository = github_repository.ramonacat-monorepo-secret.name
  branch     = github_branch.ramonacat-monorepo-secret--main.branch
}

resource "github_actions_repository_permissions" "ramonacat-monorepo-secret" {
  repository      = github_repository.ramonacat-monorepo-secret.name
  allowed_actions = "all"
}
