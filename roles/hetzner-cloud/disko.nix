{inputs, ...}: {
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
