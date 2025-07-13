{config, ...}: {
  config = {
    services.atuin = {
      enable = true;
      openRegistration = true;
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [config.services.atuin.port];
  };
}
