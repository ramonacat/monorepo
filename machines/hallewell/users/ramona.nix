{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    home-manager.users.ramona = {
      home.packages = with pkgs; [
        k3b
      ];
    };
  };
}
