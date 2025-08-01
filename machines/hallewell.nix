_: {
  imports = [
    ../roles/all.nix
    ../roles/private.nix
    ../roles/installed.nix

    ./hallewell/arrsuite.nix
    ./hallewell/atuin-server.nix
    ./hallewell/github-runner.nix
    ./hallewell/grafana.nix
    ./hallewell/hardware.nix
    ./hallewell/minecraft.nix
    ./hallewell/minio.nix
    ./hallewell/nas.nix
    ./hallewell/navidrome.nix
    ./hallewell/networking.nix
    ./hallewell/nginx.nix
    ./hallewell/paperless.nix
    ./hallewell/photoprism.nix
    ./hallewell/postgresql.nix
    ./hallewell/ras2.nix
    ./hallewell/ratweb2.nix
    ./hallewell/telegraf.nix
    ./hallewell/tempo.nix
    ./hallewell/znc.nix

    ../users/ramona/installed.nix
    ../users/root/base.nix
  ];
}
