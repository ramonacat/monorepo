{config, ...}: {
  config = {
    services.atuin = {
      enable = true;
      openRegistration = true;
      host = "0.0.0.0";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [config.services.atuin.port];
  };
}
