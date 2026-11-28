{
  lib,
  config,
  ...
}:
{
  options = {
    ramona.machine = lib.mkOption {
      type =
        with lib.types;
        submodule {
          options = {
            type = lib.mkOption {
              type = enum [
                "server"
                "workstation"
                "live"
              ];
            };
            location = lib.mkOption {
              type = enum [
                "home"
                "pl1"
                # TODO remove, replace with specific regions
                "hetzner"
                "roaming"
                "contabo-eu"
                "ovh-gra1"
              ];
            };
            hasPublicIP = lib.mkOption { type = bool; };
            roles = lib.mkOption { type = listOf str; };
            tailscale-tags = lib.mkOption {
              type = listOf str;
              default = [ ];
            };
          };
        };
    };
  };
  config = {
    assertions = lib.mkIf (config.ramona.machine.type == "workstation") [
      {
        assertion = !config.ramona.machine.hasPublicIP;
        message = "workstations cannot have a public IP!";
      }
    ];
  };
}
