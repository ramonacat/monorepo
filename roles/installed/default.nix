{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.agenix.nixosModules.default

    ../../users/ramona/installed
    ../../users/root/installed

    ../../modules/updates

    ./nix.nix
    ./restic-home.nix
    ./ssh.nix
    ./tailscale.nix
    ./syslog.nix
    ./prometheus-exporter.nix
  ];
  config = {
    services.fwupd.enable = lib.mkDefault true;
    environment.systemPackages = with pkgs; [ pciutils ];
    security.polkit.enable = true;
    programs.nix-ld.enable = true;
    ramona.machine.roles = [ "installed" ];
  };
}
