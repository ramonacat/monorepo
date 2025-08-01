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

    services.restic.backups.grafana = import ../../libs/nix/mk-restic-config.nix config {
      timerConfig = {
        OnCalendar = "*-*-* 00/1:00:00";
        RandomizedDelaySec = "30m";
      };
      paths = [
        config.services.grafana.dataDir
      ];
    };
  };
}
