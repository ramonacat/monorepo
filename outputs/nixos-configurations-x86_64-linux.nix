{
  pkgs,
  inputs,
  flake,
  ...
}: let
  machines = pkgs.lib.mapAttrsToList (hostname: _: hostname) (builtins.readDir ../machines);
in
  pkgs.lib.genAttrs machines (
    hostname:
      inputs.nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64";
        specialArgs = {
          inherit inputs flake;
        };
        modules = [
          (../machines + "/${hostname}")
        ];
      }
  )
