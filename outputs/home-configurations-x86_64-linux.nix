{
  pkgs,
  inputs,
  flake,
  ...
}: {
  "ramona-wsl" = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {
      inherit inputs flake;
    };

    modules = [
      ../users/ramona/home-manager/base
      ../users/ramona/home-manager/wsl
      ../users/ramona/home-manager/workstation
    ];
  };
}
