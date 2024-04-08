_: {
  config = {
    services.jackett.enable = true;
    services.radarr.enable = true;
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      9117 # jackett
      7878 # radarr
    ];
  };
}
