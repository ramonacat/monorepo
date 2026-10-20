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
      extraOptions = "--firewall-backend=nftables";
    };

    # needed to keep DNS and tailscale routing in docker working predictably
    # https://tailscale.com/security-bulletins#ts-2024-005
    services.tailscale.extraUpFlags = [ "--stateful-filtering=false" ];

    # TODO this probably should be just set by default on all machines
    systemd.services.tailscaled = {
      serviceConfig.Environment = [
        "TS_DEBUG_FIREWALL_MODE=nftables"
      ];
    };
  };
}
