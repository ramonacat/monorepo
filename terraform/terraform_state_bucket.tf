resource "b2_bucket" "tfstate" {
  bucket_name = "ramona-fun-tfstate"
  bucket_type = "allPrivate"
}
