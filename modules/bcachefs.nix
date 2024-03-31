{
  lib,
  pkgs,
  ...
}: {
  config = {
    boot = {
      kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
      supportedFilesystems = ["bcachefs"];
      initrd.supportedFilesystems = ["bcachefs"];
    };
  };
}
