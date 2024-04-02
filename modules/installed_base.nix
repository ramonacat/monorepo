{
  lib,
  pkgs,
  ...
}: {
  config = {
    services = {
      openssh = {
        enable = true;
        openFirewall = false;
        settings.X11Forwarding = true;
      };
      fwupd.enable = lib.mkDefault true;
      tailscale = {
        enable = true;
        useRoutingFeatures = "both";
        extraUpFlags = ["--advertise-exit-node"];
      };
    };
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHW4PIqcucwZdFj5u9aMhLj/ernBFV24PyHuspHwh3LT ramona@moonfall"
    ];
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22];
    environment.systemPackages = with pkgs; [pciutils tailscale];
    security.polkit.enable = true;
    security.pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
      swaylock.u2fAuth = true;
    };
    programs.nix-ld.enable = true;

    nix.optimise.automatic = true;
    nix.gc.automatic = true;
  };
}
