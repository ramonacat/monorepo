resource "google_storage_bucket" "tfstate" {
  name                     = "ramona-fun-tfstate"
  location                 = "EU"
  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }
}

resource "b2_bucket" "tfstate" {
  bucket_name = "ramona-fun-tfstate"
  bucket_type = "allPrivate"
}
