{
  pkgs,
  config,
  lib,
  ...
}: {
  options = {
    services.ramona.monorepo-github-runner = lib.mkOption {
      description = "github runner for this monorepo";
      default = {};
      type = with lib.types;
        submodule {
          options = {
            enable = lib.mkOption {type = bool;};
            count = lib.mkOption {type = int;};
          };
        };
    };
  };

  config = let
    runner = config.services.ramona.monorepo-github-runner;
  in
    lib.mkIf runner.enable {
      age.secrets.github-pat-runner-registration = {
        file = ../secrets/github-pat-runner-registration.age;
      };

      services.github-runners = lib.mergeAttrsList (builtins.map (i: {
        "${config.networking.hostName}-${toString i}" = {
          enable = true;
          url = "https://github.com/ramonacat/monorepo";
          tokenFile = config.age.secrets.github-pat-runner-registration.path;
          extraLabels = ["nixos"];
          extraPackages = with pkgs; [openssh jq proot];
          replace = true;
        };
      }) (lib.range 1 runner.count));
    };
}
