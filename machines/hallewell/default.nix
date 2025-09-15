_: {
  imports = [
    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private
    ../../roles/tailscale-nginx
    ../../roles/builds-host

    ../../users/ramona/installed
    ../../users/root/installed

    ./nas
    ./nginx
    ./paperless

    ./atuin-server.nix
    ./github-runner.nix
    ./grafana.nix
    ./hardware.nix
    ./jellyfin.nix
    ./minecraft.nix
    ./minio.nix
    ./navidrome.nix
    ./networking.nix
    ./photoprism.nix
    ./postgresql.nix
    ./ras2.nix
    ./servarr.nix
    ./telegraf.nix
    ./tempo.nix
    ./znc.nix
  ];
  config = {
    ramona.machine.location = "home";
  };
}
