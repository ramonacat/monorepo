resource "github_repository" "ramonacat-monorepo" {
  name        = "monorepo"
  visibility  = "public"
  description = "This is a monorepo that contains most of my apps and computer configurations."

  allow_merge_commit = true
  allow_rebase_merge = false
  allow_squash_merge = false

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

resource "github_repository_deploy_key" "ramonacat-monorepo--forgejo-mirror" {
  title      = "forgejo mirror"
  repository = github_repository.ramonacat-monorepo.name
  key        = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK8qhu6NoFvmNMiMk4LxcrtxtfxYrIs0FyL0BzKCrNW0"
  read_only  = false
}
