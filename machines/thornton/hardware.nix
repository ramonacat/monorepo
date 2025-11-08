_: {
  config = {
    fileSystems = {
      "/var/lib/postgresql" = {
        device = "/dev/sdb";
        fsType = "ext4";
      };
    };
  };
}
