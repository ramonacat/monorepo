{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./_notlive/restic.nix
    ./_notlive/ssh.nix
    ./_notlive/nas-client.nix
    ./_notlive/tailscale.nix
    ./_notlive/rad.nix
    ./_notlive/syncthing.nix
    ./_notlive/telegraf.nix
    ./_notlive/updates.nix
    ./_notlive/nix.nix
  ];
  config = {
    services = {
      fwupd.enable = lib.mkDefault true;
    };
    environment.systemPackages = with pkgs; [
      pciutils
    ];
    security.polkit.enable = true;
    programs.nix-ld.enable = true;
  };
}
