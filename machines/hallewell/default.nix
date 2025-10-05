_: {
  imports = [
    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private
    ../../roles/tailscale-nginx
    ../../roles/builds-host

    ./nas
    ./nginx
    ./paperless

    ./atuin-server.nix
    ./bcachefs.nix
    ./github-runner.nix
    ./hardware.nix
    ./jellyfin.nix
    ./minecraft.nix
    ./navidrome.nix
    ./networking.nix
    ./photoprism.nix
    ./postgresql.nix
    ./servarr.nix
    ./telegraf.nix
    ./znc.nix
  ];
  config = {
    ramona.machine.location = "home";
  };
}
