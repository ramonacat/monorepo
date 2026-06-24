resource "b2_bucket" "uploads" {
  bucket_name = "ramona-uploads"
  bucket_type = "allPublic"
}
