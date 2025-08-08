{
  pkgs,
  inputs,
  flake,
  ...
}: let
  users = builtins.readDir ../users;
  configurations = pkgs.lib.flatten (
    pkgs.lib.mapAttrsToList
    (
      user: _: let
        home-manager-directory = ../users + "/${user}/home-manager";
      in
        pkgs.lib.mapAttrsToList
        (variant: _: {
          inherit user variant;
          path = home-manager-directory + "/${variant}";
        })
        (
          if builtins.pathExists home-manager-directory
          then builtins.readDir home-manager-directory
          else {}
        )
    )
    users
  );
in
  pkgs.lib.mergeAttrsList (builtins.map (x: {
      "${x.user}-${x.variant}" = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs flake;
        };

        modules = [
          x.path
        ];
      };
    })
    configurations)
