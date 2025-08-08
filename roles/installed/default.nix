{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.agenix.nixosModules.default

    ./nix.nix
    ./rad.nix
    ./restic-home.nix
    ./ssh.nix
    ./tailscale.nix
    ./telegraf.nix
    ./updates.nix
  ];
  config = {
    services.fwupd.enable = lib.mkDefault true;
    environment.systemPackages = with pkgs; [pciutils];
    security.polkit.enable = true;
    programs.nix-ld.enable = true;
  };
}
