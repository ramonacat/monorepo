{ lib, modulesPath, pkgs, ... }:
{
  config = {
    services.openssh.enable = true;
    environment.systemPackages = with pkgs; [ pciutils ];
  };
}
