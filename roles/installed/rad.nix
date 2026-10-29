{
  lib,
  pkgs,
  config,
  ...
}:
{
  options = {
    ramona = {
      mikrotik = lib.mkOption {
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
                    available_ports = lib.mkOption {
                      type = listOf port;
                      default = [
                      ];
                    };
                    key_path = lib.mkOption {
                      type = str;
                      default = "/var/ramona/rad/wireguard.key";
                    };
                  };
                };
              };
            };
          };
      };
      router =
        with lib.types;
        lib.mkOption {
          type = submodule {
            options = {
              enabled = lib.mkOption {
                type = bool;
                default = false;
              };
              filter_import = lib.mkOption {
                type = str;
                default = ''
                  if net ~ [ 10.0.0.0/8+ ] then {
                      accept "importing local network routes";
                  }

                  reject "rejected global ip or unknown local network";
                '';
              };
              filter_export = lib.mkOption {
                type = str;
                default = ''
                  if net ~ [10.0.0.0/8+] then {
                      accept "exporting local network routes";
                  }

                  reject "rejected global ip or unknown local network";
                '';
              };
              additional_config = lib.mkOption {
                type = str;
                default = "";
              };
              interfaces = lib.mkOption {
                type = listOf (submodule {
                  options = {
                    name_pattern = lib.mkOption {
                      type = str;
                    };
                    cost = lib.mkOption { type = int; };
                    is_tunnel = lib.mkOption {
                      type = bool;
                      default = false;
                    };
                  };
                });
              };
              bird_config = lib.mkOption {
                type = str;
                default = "/var/ramona/bird.conf";
              };
              wireguard = lib.mkOption {
                type =
                  with lib.types;
                  submodule {
                    options = {
                      host = lib.mkOption {
                        type = nullOr str;
                        default = null;
                      };
                      available_ports = lib.mkOption {
                        type = nullOr (listOf port);
                        default = [
                          51820
                          51821
                          51822
                          51823
                          51824
                          51825
                          51826
                          51827
                          51828
                          51829
                        ];
                      };
                    };
                  };
              };
            };
          };
        };
      host-group-name = lib.mkOption { type = with lib.types; nullOr str; };
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
              state = "/var/ramona/rad/state.json";
              host_group_name = config.ramona.host-group-name;
            }
            // (
              if !config.ramona.router.enabled then
                { }
              else
                {
                  wireguard =
                    (
                      if config.ramona.router.wireguard.host == null then
                        { endpoint = "Auto"; }
                      else
                        {
                          inherit (config.ramona.router.wireguard) host available_ports;
                          endpoint = "Specified";
                        }
                    )
                    // {
                      key_file = "/var/ramona/wireguard.key";
                    };
                  routing = {
                    inherit (config.ramona.router)
                      interfaces
                      filter_import
                      filter_export
                      bird_config
                      additional_config
                      ;
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
    networking.firewall.allowedUDPPorts = lib.mkIf config.ramona.router.enabled config.ramona.router.wireguard.available_ports;
    ramona.router = {
      interfaces = [
        {
          name_pattern = "wg-*";
          cost = 10000;
          is_tunnel = true;
        }
        {
          name_pattern = "lb-*";
          cost = 1;
          is_tunnel = false;
        }
      ];
    };
  };
}
