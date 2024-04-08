_: {
  config = {
    services.jackett.enable = true;
    services.radarr = {
      enable = true;
      user = "nas";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      9117 # jackett
      7878 # radarr
    ];
  };
}
