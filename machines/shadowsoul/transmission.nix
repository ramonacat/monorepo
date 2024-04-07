_: {
  config = {
    services.transmission = {
      enable = true;
      openFirewall = true;
      performanceNetParameters = true;
      settings = {
        peer-port = 51413;
        peer-port-random-on-start = false;
        utp-enabled = true;
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [9001];
  };
}
