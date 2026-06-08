{
  lib,
  flake,
  ...
}:
{
  config = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings =
        let
          hosts = import ../../../../data/hosts.nix { inherit flake lib; };
        in
        builtins.listToAttrs (
          map (hostname: {
            name = "Match ${hostname}";
            value = {
              ForwardAgent = true;
            };
          }) hosts.nixos
        );
    };
  };
}
