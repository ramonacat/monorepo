{ inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
  ];
  config = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/sda";
          content = {
            type = "table";
            format = "msdos";
            partitions = [
              {
                name = "rootfs";
                bootable = true;
                start = "1M";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              }
            ];
          };
        };
      };
    };
  };
}
