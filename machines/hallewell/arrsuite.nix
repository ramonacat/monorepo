_: {
  config = {
    services.jackett.enable = true;
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [9117];
  };
}
