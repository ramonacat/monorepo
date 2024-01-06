{ config, pkgs, lib, ... }:
{
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
  };
}
