{ lib, modulesPath, pkgs, ... }:
{
  config = {
    services.openssh.enable = true;
    services.fwupd.enable = true;
    environment.systemPackages = with pkgs; [ pciutils ];
  };
}
