{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports =
    [
      inputs.agenix.nixosModules.default
    ]
    ++ import ../../libs/nix/nix-files-from-dir.nix ./.;
  config = {
    services.fwupd.enable = lib.mkDefault true;
    environment.systemPackages = with pkgs; [pciutils];
    security.polkit.enable = true;
    programs.nix-ld.enable = true;
  };
}
