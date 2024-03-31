{...}: {
  config = let
    port = 3000;
  in {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = port;
          domain = "hallewell.ibis-draconis.ts.net";
        };
      };
    };
    networking.firewall.allowedTCPPorts = [port];
  };
}
