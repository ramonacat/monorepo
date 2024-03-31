{
  lib,
  pkgs,
  ...
}: {
  config = {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    boot.supportedFilesystems = ["bcachefs"];
    boot.initrd.supportedFilesystems = ["bcachefs"];
  };
}
