resource "github_repository" "ramonacat-monorepo-secret" {
  name        = "monorepo-secret"
  visibility  = "private"
  description = "This repository has been archived. Talk to me to request access to https://code.ramona.fun/ramona/monorepo-secret"

  allow_merge_commit = true
  allow_rebase_merge = false
  allow_squash_merge = false

  allow_auto_merge = true

  has_issues   = true
  has_projects = false
  has_wiki     = false

  archived = true
}

resource "github_branch" "ramonacat-monorepo-secret--main" {
  repository = github_repository.ramonacat-monorepo-secret.name
  branch     = "main"
}

resource "github_branch_default" "ramonacat-monorepo-secret--main" {
  repository = github_repository.ramonacat-monorepo-secret.name
  branch     = github_branch.ramonacat-monorepo-secret--main.branch
}
