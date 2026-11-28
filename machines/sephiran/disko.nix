{ inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
  ];
  config = {
    disko.devices = {
      disk = builtins.listToAttrs (
        map
          (name: {
            inherit name;

            value = {
              type = "disk";
              device = "/dev/${name}";
              content = {
                type = "gpt";
                partitions = {
                  boot = {
                    type = "EF00";
                    size = "512M";
                    content = {
                      type = "mdraid";
                      name = "boot";
                    };
                  };
                  swap = {
                    size = "8G";
                    content = {
                      type = "swap";
                    };
                  };
                  primary = {
                    size = "100%";
                    content = {
                      type = "lvm_pv";
                      vg = "pool";
                    };
                  };
                };
              };
            };
          })
          [
            "sda"
            "sdb"
            "sdc"
            "sdd"
          ]
      );
      mdadm = {
        boot = {
          type = "mdadm";
          level = 1;
          metadata = "1.0";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
      };
      lvm_vg = {
        pool = {
          type = "lvm_vg";
          lvs = {
            root = {
              size = "100%";
              lvm_type = "raid5";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "defaults" ];
              };
            };
          };
        };
      };
    };
  };
}
