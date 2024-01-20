{ config, pkgs, lib, ... }:
{
  config = {
    services.fail2ban.enable = true;
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
}
