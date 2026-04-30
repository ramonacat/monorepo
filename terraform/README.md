# Set up credentials
```
cd ../secrets/
agenix -d terraform-tokens.age > ~/terraform-tokens
chmod 0600 ~/terraform-tokens

cd -

gcloud auth application-default login
```
