plugin "terraform" {
  enabled = true
  preset  = "recommended"
  // https://github.com/terraform-linters/tflint/issues/2594#issuecomment-5000385760
  // https://github.com/terraform-linters/tflint/issues/2596
  signature = "pgp"
}

plugin "style-guide" {
  enabled = true
  version = "0.2.0"
  source  = "github.com/miztch/tflint-ruleset-style-guide"
  // https://github.com/terraform-linters/tflint/issues/2594#issuecomment-5000385760
  // https://github.com/terraform-linters/tflint/issues/2596
  signature = "pgp"

  signing_key = <<-KEY
    -----BEGIN PGP PUBLIC KEY BLOCK-----

    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
    H/hO
    =DyOO
    -----END PGP PUBLIC KEY BLOCK-----
  KEY
}

plugin "opa" {
  enabled = true
  version = "0.10.0"
  source  = "github.com/terraform-linters/tflint-ruleset-opa"
  // https://github.com/terraform-linters/tflint/issues/2594#issuecomment-5000385760
  // https://github.com/terraform-linters/tflint/issues/2596
  signature = "pgp"
}
