_: {
  imports = [
    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private
    ../../roles/builds-host

    ./immich
    ./jellyfin
    ./nas
    ./paperless

    ./atuin-server.nix
    ./autounrar-dls.nix
    ./bcachefs.nix
    ./caddy.nix
    ./github-runner.nix
    ./hardware.nix
    ./navidrome.nix
    ./networking.nix
    ./postgresql.nix
    ./servarr.nix
    ./znc.nix
    ./woodpecker-agent.nix
  ];
  config = {
    ramona.machine.location = "home";
    virtualisation.docker = {
      autoPrune = {
        enable = true;
        dates = "daily";
      };
      daemon.settings = {
        "data-root" = "/mnt/nas3/docker/";
      };
    };
  };
}
