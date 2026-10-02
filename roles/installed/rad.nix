{
  lib,
  pkgs,
  config,
  ...
}:
{
  options = {
    ramona.mikrotik = lib.mkOption {
      type =
        with lib.types;
        submodule {
          options = {
            enabled = lib.mkOption {
              type = bool;
              default = false;
            };
            endpoint = lib.mkOption { type = str; };
            username = lib.mkOption {
              type = str;
            };
            password = lib.mkOption {
              type = oneOf [
                str
                /*
                  TODO with two submodlues in oneOf nix just tries the first one so this is fucked (submodule {
                    options = {
                      path = lib.mkOption {
                        type = str;
                      };
                    };
                  })
                */
                (submodule {
                  options = {
                    env = lib.mkOption {
                      type = str;
                    };
                  };
                })
              ];
            };
            wireguard = lib.mkOption {
              type = submodule {
                options = {
                  endpoint = lib.mkOption {
                    type = enum [
                      "Specified"
                      "Auto"
                      "InitiatorOnly"
                    ];
                  };
                  host = lib.mkOption {
                    type = str;
                    default = "";
                  };
                  port = lib.mkOption {
                    type = port;
                    default = 0;
                  };
                  interface = lib.mkOption {
                    type = str;
                    default = "";
                  };
                };
              };
            };
          };
        };
    };
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
          builtins.toJSON (
            {
              certificate = "/var/ramona/identity/certificate.crt";
              key = "/var/ramona/identity/certificate.key";
            }
            // (
              if !config.ramona.router.wireguard.enabled then
                { }
              else
                {
                  wireguard =
                    (
                      if config.ramona.router.wireguard.host == null then
                        { endpoint = "Auto"; }
                      else
                        {
                          endpoint = "Specified";
                          host = config.ramona.router.wireguard.host;
                          port = config.ramona.router.wireguard.port;
                        }
                    )
                    // {
                      key_file = "/var/ramona/wireguard.key";
                    };
                }
            )
            // (
              if !config.ramona.mikrotik.enabled then
                { }
              else
                {
                  mikrotik =
                    let
                      c = config.ramona.mikrotik;
                    in
                    {
                      inherit (c)
                        endpoint
                        username
                        password
                        wireguard
                        ;
                    };
                }
            )
          )
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
    networking.firewall.allowedUDPPorts = lib.mkIf config.ramona.router.wireguard.enabled [
      config.ramona.router.wireguard.port
    ];
  };
}
