resource "google_storage_bucket" "tfstate" {
  name                     = "ramona-fun-tfstate"
  location                 = "EU"
  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }
}
