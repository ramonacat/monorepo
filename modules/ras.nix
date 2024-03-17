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
      systemd.services.ras = {
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          DynamicUser = true;
          ExecStart = "${pkgs.ramona.ras}/bin/ras ${rasConfig.dataFile}";
          ReadWritePaths = "${rasConfig.dataFile}";
        };
      };
    };
}
