{
  lib,
  modulesPath,
  pkgs,
  config,
  ...
}: {
  config = {
    boot.supportedFilesystems = lib.mkForce [
      "btrfs"
      "cifs"
      "f2fs"
      "jfs"
      "ntfs"
      "reiserfs"
      "vfat"
      "xfs"
      "bcachefs"
    ];
  };
}
