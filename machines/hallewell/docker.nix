_: {
  config = {
    virtualisation.docker = {
      autoPrune = {
        enable = true;
        dates = "daily";
      };
      daemon.settings = {
        "data-root" = "/mnt/nas3/docker/";
      };
    };

    # needed to keep DNS and tailscale routing in docker working predictably
    # https://tailscale.com/security-bulletins#ts-2024-005
    services.tailscale.extraUpFlags = [ "--stateful-filtering=false" ];
  };
}
