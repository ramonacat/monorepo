_: {
  imports = [
    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private
    ../../roles/tailscale-nginx
    ../../roles/builds-host

    ./jellyfin
    ./nas
    ./nginx
    ./paperless

    ./atuin-server.nix
    ./autounrar-dls.nix
    ./bcachefs.nix
    ./github-runner.nix
    ./hardware.nix
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
