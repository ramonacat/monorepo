resource "b2_bucket" "attic" {
  bucket_name = "ramona-attic"
  bucket_type = "allPrivate"

  lifecycle_rules {
    file_name_prefix                                       = ""
    days_from_hiding_to_deleting                           = 1
    days_from_starting_to_canceling_unfinished_large_files = 1
  }
}

resource "b2_application_key" "attic" {
  key_name     = "ramona-attic"
  capabilities = ["deleteFiles", "listBuckets", "listFiles", "readBucketEncryption", "readBuckets", "readFiles", "shareFiles", "writeBucketEncryption", "writeFiles"]
  bucket_ids   = [b2_bucket.attic.bucket_id]
}

resource "vault_kv_secret_v2" "attic-storage" {
  mount = vault_mount.kv-kubernetes-darkmore.path
  name  = "attic/object-storage"
  data_json = jsonencode({
    AWS_ACCESS_KEY_ID     = b2_application_key.attic.application_key_id
    AWS_SECRET_ACCESS_KEY = b2_application_key.attic.application_key
  })
}
