{config, ...}: {
  config = {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
          domain = "hallewell.ibis-draconis.ts.net";
        };
      };
    };
    networking.firewall.allowedTCPPorts = [config.services.grafana.settings.server.http_port];
  };
}
