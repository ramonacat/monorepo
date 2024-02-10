{ ratPackage }:
{ lib, modulesPath, pkgs, config, ... }:
{
  options = {
    programs.rat = {
      enable = lib.mkEnableOption "rat";
      dataFile = lib.mkOption {
        type = lib.types.path;
        default = "";
      };
    };
  };
  config =
    let
      cfg = config.programs.rat;
    in
    lib.mkIf cfg.enable {
      home.packages = [ ratPackage ];
      xdg.configFile."rat/config.json".text = if cfg.dataFile != "" then (builtins.toJSON { storage_path = cfg.dataFile; }) else (builtins.toJSON { });
    };
}
