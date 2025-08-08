_: {
  imports = [
    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private

    ../../users/ramona/installed
    ../../users/root/installed

    ./nginx
    ./nas

    ./atuin-server.nix
    ./github-runner.nix
    ./grafana.nix
    ./hardware.nix
    ./minecraft.nix
    ./minio.nix
    ./navidrome.nix
    ./networking.nix
    ./nix-serve.nix
    ./paperless.nix
    ./photoprism.nix
    ./postgresql.nix
    ./ras2.nix
    ./servarr.nix
    ./telegraf.nix
    ./tempo.nix
    ./znc.nix
  ];
}
