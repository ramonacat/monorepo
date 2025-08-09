{
  pkgs,
  package-versions,
  ...
}:
pkgs.mkShell {
  packages = with pkgs; [
    google-cloud-sdk
    jq
    nil
    nushell
    phpactor
    postgresql_16
    rust-analyzer
    shellcheck
    shfmt
    terraform
    terraform-ls
    bash-language-server

    package-versions.nodejs
    package-versions.php-dev
    package-versions.php-packages.composer
    package-versions.rust-version
  ];
  RAMONA_FLAKE_ROOT = ./.;
}
