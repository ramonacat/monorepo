{config, ...}: {
  config = {
    services.redis.servers."" = {
      enable = true;
      bind = null;
      settings = {
        protected-mode = "no";
      };
    };

    networking.firewall.interfaces.podman0.allowedTCPPorts = [config.services.redis.servers."".port];
  };
}
