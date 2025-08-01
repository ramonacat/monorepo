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

      services.github-runners = builtins.listToAttrs (builtins.map
        (i: {
          name = "${config.networking.hostName}-${toString i}";
          value = {
            enable = true;
            url = "https://github.com/ramonacat/monorepo";
            tokenFile = config.age.secrets.github-pat-runner-registration.path;
            extraLabels = ["nixos"];
            extraPackages = with pkgs; [openssh];
            replace = true;
          };
        })
        (lib.range 0 runner.count));

      users.users.root.openssh.authorizedKeys.keys = [
        (import ../data/ssh-keys.nix).root.ci
      ];
    };
}
