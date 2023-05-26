{ lib, modulesPath, pkgs, ... }:
{
  config = {
    services.openssh.enable = true;
    networking.firewall.allowedTCPPorts = [ 22 ];
    services.fwupd.enable = true;
    environment.systemPackages = with pkgs; [ pciutils tailscale ];
  };
}
