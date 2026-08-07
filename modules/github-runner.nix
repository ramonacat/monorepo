{
  pkgs,
  config,
  lib,
  ...
}:
{
  options = {
    #TODO this should be a role
    services.ramona.monorepo-github-runner = lib.mkOption {
      description = "github runner for this monorepo";
      default = { };
      type =
        with lib.types;
        submodule {
          options = {
            enable = lib.mkOption { type = bool; };
            count = lib.mkOption { type = int; };
          };
        };
    };
  };

  config =
    let
      runner = config.services.ramona.monorepo-github-runner;
    in
    lib.mkIf runner.enable {
      age.secrets.github-pat-runner-registration = {
        file = ../secrets/github-pat-runner-registration.age;
      };
      users.groups.github-runners = { };
      users.users.github-runners = {
        isSystemUser = true;
        group = "github-runners";
        extraGroups = [ "docker" ];
      };
      nix.settings.trusted-users = [ "github-runners" ];
      virtualisation.docker = {
        enable = true;
      };
      services.github-runners = lib.mergeAttrsList (
        map (i: {
          "${config.networking.hostName}-${toString i}" = {
            enable = true;
            user = "github-runners";
            group = "github-runners";
            url = "https://github.com/ramonacat/monorepo";
            tokenFile = config.age.secrets.github-pat-runner-registration.path;
            extraLabels = [ "nixos" ];
            extraPackages = with pkgs; [
              # TODO these should probably be managed by the pipelines instead with devshells or something
              openssh
              jq
              proot
              curl
              ramona.fup
              docker
            ];
            replace = true;
            nodeRuntimes = [ "node24" ];
          };
          "${config.networking.hostName}-${toString i}-secret" = {
            enable = true;
            user = "github-runners";
            group = "github-runners";
            url = "https://github.com/ramonacat/monorepo-secret";
            tokenFile = config.age.secrets.github-pat-runner-registration.path;
            extraLabels = [ "nixos" ];
            extraPackages = with pkgs; [
              # TODO these should probably be managed by the pipelines instead with devshells or something
              openssh
              jq
              proot
              curl
              ramona.fup
              docker
            ];
            replace = true;
            nodeRuntimes = [ "node24" ];
          };
        }) (lib.range 1 runner.count)
      );
    };
}
