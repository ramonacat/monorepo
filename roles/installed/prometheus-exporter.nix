{ config, ... }: {
  config = {
    services.prometheus.exporters = {
      node = {
        enable = true;
      };
      smartctl = {
        enable = true;
      };
      systemd = {
        enable = true;
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      config.services.prometheus.exporters.node.port
      config.services.prometheus.exporters.smartctl.port
      config.services.prometheus.exporters.systemd.port
    ];
  };
}
