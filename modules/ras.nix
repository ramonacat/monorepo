{
  lib,
  pkgs,
  config,
  ...
}: {
  options = {
    services.ramona.ras = {
      enable = lib.mkEnableOption "Enable ras";
      dataFile = lib.mkOption {
        type = lib.types.str;
      };
    };
  };
  config = let
    rasConfig = config.services.ramona.ras;
  in
    lib.mkIf rasConfig.enable {
      age.secrets.ras-environment = {
        file = ../secrets/ras-environment.age;
      };
      systemd.services.ras = {
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          User = "ras";
          ExecStart = "${pkgs.ramona.ras}/bin/ras ${rasConfig.dataFile}";
          ReadWritePaths = "${rasConfig.dataFile}";
          EnvironmentFile = config.age.secrets.ras-environment.path;
          Restart = "always";
          RestartSec = "5s";
        };
      };

      users.groups.ras = {};
      users.users.ras = {
        isSystemUser = true;
        group = "ras";
        extraGroups = ["telegraf"];
      };
    };
}
