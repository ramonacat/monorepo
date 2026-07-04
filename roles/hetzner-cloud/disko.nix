{ inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
  ];
  config = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/disk/by-path/pci-0000:06:00.0-scsi-0:0:0:0";
          content = {
            type = "table";
            format = "msdos";
            partitions = [
              {
                name = "ESP";
                start = "1M";
                end = "513M";
                bootable = true;
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              }
              {
                name = "rootfs";
                start = "513M";
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
