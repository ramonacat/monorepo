{
  lib,
  pkgs,
  ...
}: {
  config = {
    home-manager.useGlobalPkgs = true;
    home-manager.users.ramona = import ./home-manager.nix {inherit pkgs lib;};

    users.users.ramona = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager" "docker" "cdrom" "audio" "adbusers"];
      openssh.authorizedKeys.keys = let
        ssh-keys = import ../../data/ssh-keys.nix;
      in [
        ssh-keys.ramona
        ssh-keys.ramona-nitrokey
        ssh-keys.ramona-nitrokey3
      ];
      shell = pkgs.bash;
    };
  };
}
