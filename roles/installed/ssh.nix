{config, ...}: {
  config = {
    services.openssh = {
      openFirewall = false;
    };
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = config.services.openssh.ports;
  };
}
