{ratPackage}: {
  lib,
  modulesPath,
  pkgs,
  config,
  ...
}: {
  options = {
    programs.rat = {
      enable = lib.mkEnableOption "rat";
      serverAddress = lib.mkOption {
        type = lib.types.str;
      };
    };
  };
  config = let
    cfg = config.programs.rat;
  in
    lib.mkIf cfg.enable {
      home.packages = [ratPackage];
      xdg.configFile."rat/config.json".text =
        if cfg.serverAddress != ""
        then (builtins.toJSON {server_address = cfg.serverAddress;})
        else (builtins.toJSON {});
    };
}
