{ lib, modulesPath, pkgs, ... }:
{
  config = {
    services.openssh.enable = true;
    services.openssh.settings.X11Forwarding = true;
    networking.firewall.allowedTCPPorts = [ 22 ];
    services.fwupd.enable = true;
    environment.systemPackages = with pkgs; [ pciutils tailscale cachix ];
    services.tailscale.enable = true;
  };
}
