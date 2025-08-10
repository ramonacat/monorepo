{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.agenix.nixosModules.default

    ./updates

    ./nix.nix
    ./rad.nix
    ./restic-home.nix
    ./ssh.nix
    ./tailscale.nix
    ./telegraf.nix
  ];
  config = {
    services.fwupd.enable = lib.mkDefault true;
    environment.systemPackages = with pkgs; [pciutils];
    security.polkit.enable = true;
    programs.nix-ld.enable = true;
    ramona.roles = ["installed"];
  };
}
