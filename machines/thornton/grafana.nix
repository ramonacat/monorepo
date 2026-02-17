{
  config,
  pkgs,
  ...
}: {
  config = {
    age.secrets.grafana-secret-key = {
      file = ../../secrets/grafana-secret-key.age;
      group = "grafana";
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
          domain = "thornton.ibis-draconis.ts.net";
        };
        security = {
          secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [config.services.grafana.settings.server.http_port];

    services.restic.backups.grafana = import ../../libs/nix/mk-restic-config.nix {inherit config pkgs;} {
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
