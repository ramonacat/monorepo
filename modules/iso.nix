{lib, ...}: {
  config = {
    # the base configuration sets this to an empty string, we don't want passwordless root, but instead the password set from secrets in the base module.
    users.users.root.initialHashedPassword = lib.mkForce null;

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
