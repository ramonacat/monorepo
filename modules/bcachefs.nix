{ lib, modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  config = {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_testing;
    boot.supportedFilesystems = [ "bcachefs" ];
    boot.initrd.supportedFilesystems = [ "bcachefs" ];
  };
}
