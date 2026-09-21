{
  lib,
  pkgs,
  config,
  ...
}:
{
  options = {
    ramona.router.wireguard = lib.mkOption {
      type =
        with lib.types;
        submodule {
          options = {
            enabled = lib.mkOption {
              type = bool;
              default = false;
            };
            host = lib.mkOption {
              type = nullOr str;
              default = null;
            };
            port = lib.mkOption {
              type = port;
              default = 51820;
            };
          };
        };
    };
  };
  config = {
    systemd.services.rad = {
      wantedBy = [ "multi-user.target" ];
      environment = {
        RAMONA_CONFIG_PATH = pkgs.writeText "rad.config.json" (
          builtins.toJSON {
            certificate = "/var/ramona/identity/certificate.crt";
            key = "/var/ramona/identity/certificate.key";
            wireguard =
              if !config.ramona.router.wireguard.enabled then
                { "endpoint" = "Disabled"; }
              else
                (
                  if config.ramona.router.wireguard.host == null then
                    { endpoint = "Auto"; }
                  else
                    {
                      endpoint = "Specified";
                      host = config.ramona.router.wireguard.host;
                      port = config.ramona.router.wireguard.port;
                    }
                );
          }
        );
      };
      unitConfig = {
        StartLimitIntervalSec = 5;
      };
      serviceConfig = {
        RestartSec = "10s";
        Restart = "on-failure";
        ExecStart = "${pkgs.ramona.rad}/bin/rad";
        AmbientCapabilities = "CAP_NET_RAW CAP_NET_ADMIN";
        CapabilityBoundingSet = "CAP_NET_RAW CAP_NET_ADMIN";
      };
    };
  };
}
