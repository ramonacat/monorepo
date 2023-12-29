{ lib, modulesPath, pkgs, ... }:
{
  config = {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_testing;
    boot.supportedFilesystems = [ "bcachefs" ];
    boot.initrd.supportedFilesystems = [ "bcachefs" ];
  };
}
