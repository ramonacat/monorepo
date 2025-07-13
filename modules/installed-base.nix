{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./installed-base/initrd-ssh.nix
    ./installed-base/restic.nix
  ];
  config = {
    services = {
      openssh = {
        openFirewall = false;
      };
      fwupd.enable = lib.mkDefault true;
      tailscale = {
        enable = true;
        useRoutingFeatures = "both";
        extraUpFlags = ["--advertise-exit-node"];
      };
    };
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22];
    environment.systemPackages = with pkgs; [
      pciutils
      tailscale
    ];
    security.polkit.enable = true;
    programs.nix-ld.enable = true;

    nix.optimise.automatic = true;
    nix.gc.automatic = true;
  };
}
