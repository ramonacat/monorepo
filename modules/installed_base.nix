{ lib, modulesPath, pkgs, ... }:
{
  config = {
    services.openssh.enable = true;
    services.openssh.settings.X11Forwarding = true;
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHW4PIqcucwZdFj5u9aMhLj/ernBFV24PyHuspHwh3LT ramona@moonfall"
    ];
    networking.firewall.allowedTCPPorts = [ 22 ];
    services.fwupd.enable = lib.mkDefault true;
    environment.systemPackages = with pkgs; [ pciutils tailscale ];
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = [ "--advertise-exit-node" ];
    };
  };
}
