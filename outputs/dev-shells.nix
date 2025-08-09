{
  pkgs,
  package-versions,
  ...
}:
pkgs.mkShell {
  # TODO make scripts/* into derivations, so those can have their dependencies defined explicitly, instead of just depending on the devshell providing them
  packages = with pkgs; [
    bash-language-server
    fleetctl
    google-cloud-sdk
    jq
    nil
    nushell
    phpactor
    postgresql_16
    rust-analyzer
    shellcheck
    shfmt
    syncthing
    terraform
    terraform-ls

    package-versions.nodejs
    package-versions.php-dev
    package-versions.php-packages.composer
    package-versions.rust-version
  ];
  RAMONA_FLAKE_ROOT = ./..;
}
