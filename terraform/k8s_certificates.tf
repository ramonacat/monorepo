resource "vault_policy" "cert-issue-kubernetes-darkmore" {
  name   = "cert-issue-kubernetes-darkmore"
  policy = <<-EOT
    path "/pki-kubernetes-darkmore/sign/internal" {
      capabilities = ["create", "patch", "read", "update"]
    }
  EOT
}

resource "vault_cert_auth_backend_role" "hosts-kubernetes-darkmore" {
  name         = "hosts-kubernetes-darkmore"
  certificate  = module.pki-hosts.certificate
  backend      = vault_auth_backend.cert.path
  ocsp_enabled = false
  token_policies = setunion(
    vault_cert_auth_backend_role.hosts.token_policies,
    [vault_policy.cert-issue-kubernetes-darkmore.name]
  )
}

resource "vault_auth_backend" "kubernetes" {
  path = "kubernetes"
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "main" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://kubernetes.default"
  issuer             = "https://kubernetes.default.svc.cluster.local"
  kubernetes_ca_cert = <<-EOT
  -----BEGIN CERTIFICATE-----
  MIIDBTCCAe2gAwIBAgIIQCsq1LiE4cUwDQYJKoZIhvcNAQELBQAwFTETMBEGA1UE
  AxMKa3ViZXJuZXRlczAeFw0yNjA2MTgxNzA2NTBaFw0zNjA2MTUxNzExNTBaMBUx
  EzARBgNVBAMTCmt1YmVybmV0ZXMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
  AoIBAQDRiO5vikNkyotk0DatfUJY7t0eZ/WkdsDtS+RuYJ2wb4jfhiAtVsVpRtnR
  FwJBCiK4aQ34N34a+VBuPxOaIIaEkufGwvkBriKGukNTA9nfhMTmClBjRVboZK4H
  HruLcX8n9/O6S505T7RY9UD9nIqDpatXrt3jKh7xWqWHUI4dJrNnRAEBKasnqT3I
  58vnVd1gL8I1514Q6iFIIEgaqWFx8Nj0k2blO3sUgCsnwailj9AFA0+Z9pIRJceg
  nZmKL9q7JqE7fb5sMs7j9Q1Qv1JWSvmsOqEjzGezXJu6+fnr50h5anpj6M25lk+n
  9scdHuWvHfjTyz0uXZdisB8tFzbPAgMBAAGjWTBXMA4GA1UdDwEB/wQEAwICpDAP
  BgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSMjGrFUqk46fy6k3O8mgrSZm5/LDAV
  BgNVHREEDjAMggprdWJlcm5ldGVzMA0GCSqGSIb3DQEBCwUAA4IBAQAacdU7rHXr
  gf+UKXylk41CIu+Ucjf9a5TPLkQgf4NcOmIXNxOHvUZ0v5Ier3X/CjztLI0LSvxc
  Anp6JYLclaVj+8JHSb0kCmc3rM7XkeI+glRdqyW4ymlMqDEqUTodHuxC3NzrtYwf
  22NPkPLAELyJpaWX6MRy/5Plk6nKUNbkpMBwimAt5/EVCDnC+f0Hzx2FB6FMSbMW
  7Ui0C3SV5WrRwLCMFvXviBpWKiTK9UQZDTCpbLP2dCS9NDnTyH8BppjcaTarQcKW
  iRr9oho1+LCFSV8vSbSsHlpTvkC7VB2t8D3WaDIvi9hVtsCgXs3UYClMCs/x4/w8
  KYGq/F/7w2rz
  -----END CERTIFICATE-----
  EOT
}

resource "vault_mount" "kv-kubernetes-darkmore" {
  path    = "secrets/kubernetes/darkmore"
  type    = "kv"
  options = { version = "2" }
}

resource "vault_kv_secret_backend_v2" "kubernetes-darkmore" {
  mount        = vault_mount.kv-kubernetes-darkmore.path
  max_versions = 5
}

resource "vault_policy" "kv-kubernetes-darkmore" {
  name   = "kv-kubernetes-darkmore"
  policy = <<-EOT
    path "/${vault_mount.kv-kubernetes-darkmore.path}/*" {
      capabilities = ["create", "update", "patch", "delete", "read", "list"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "darkmore-kv" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "kv-kubernetes-darkmore"
  bound_service_account_names      = ["vault-client"]
  bound_service_account_namespaces = ["external-secrets"]
  token_policies                   = ["default", vault_policy.kv-kubernetes-darkmore.name]
}
