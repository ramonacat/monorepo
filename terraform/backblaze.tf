resource "b2_bucket" "uploads" {
  bucket_name = "ramona-uploads"
  bucket_type = "allPublic"

  lifecycle_rules {
    file_name_prefix = ""

    days_from_hiding_to_deleting                           = 3
    days_from_starting_to_canceling_unfinished_large_files = 3
  }
}
