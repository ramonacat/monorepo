{ lib, modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  config = {
    boot.supportedFilesystems = [ "bcachefs" ];
    boot.initrd.supportedFilesystems = [ "bcachefs" ];
  }
