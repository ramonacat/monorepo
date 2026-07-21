resource "b2_bucket" "tfstate" {
  bucket_name = "ramona-fun-tfstate"
  bucket_type = "allPrivate"
}

resource "b2_bucket" "tfstate-secret" {
  bucket_name = "ramona-fun-tfstate-secret"
  bucket_type = "allPrivate"
}
