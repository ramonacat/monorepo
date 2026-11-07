_: {
  imports = [
    ../../roles/all
    ../../roles/at-home
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private

    ./immich
    ./jellyfin
    ./nas
    ./paperless

    ./attic.nix
    ./atuin-server.nix
    ./autounrar-dls.nix
    ./bcachefs.nix
    ./caddy.nix
    ./docker.nix
    ./hardware.nix
    ./navidrome.nix
    ./networking.nix
    ./postgresql.nix
    ./servarr.nix
    ./woodpecker-agent.nix
  ];
  config = {
    ramona.machine.location = "home";
  };
}
