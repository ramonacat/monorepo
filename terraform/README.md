# Set up credentials
```
cd ../secrets/
agenix -d terraform-tokens.age > ~/terraform-tokens
agenix -d minio-terraform-state.age > ~/minio-terraform-state
chmod 0600 ~/terraform-tokens
chmod 0600 ~/minio-terraform-state

cd -

gcloud auth application-default login
```
