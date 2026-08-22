resource "b2_bucket" "attic" {
  provider = b2.eu

  bucket_name = "ramona-eu-attic"
  bucket_type = "allPrivate"
}

resource "b2_application_key" "attic" {
  provider = b2.eu

  key_name     = "attic"
  capabilities = ["readFiles", "writeFiles"]
  bucket_ids   = [b2_bucket.attic.id]
}

resource "vault_kv_secret_v2" "kubernetes-darkmore-attic" {
  mount = "secrets/kubernetes/darkmore"
  name  = "attic/object-storage"
  data_json = jsonencode({
    AWS_ACCESS_KEY_ID     = b2_application_key.attic.application_key_id
    AWS_SECRET_ACCESS_KEY = b2_application_key.attic.application_key
  })
}
