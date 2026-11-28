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
                  swap = {
                    size = "8G";
                    content = {
                      preCreateHook = "sleep 3";
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
                }
                // (
                  if name == "sda" then

                    {
                      boot = {
                        type = "EF00";
                        size = "512M";
                        content = {
                          type = "filesystem";
                          preCreateHook = "sleep 3";
                          format = "vfat";
                          mountpoint = "/boot";
                          mountOptions = [ "umask=0077" ];
                        };
                      };
                    }
                  else
                    { }
                );
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
      lvm_vg = {
        pool = {
          type = "lvm_vg";
          lvs = {
            root = {
              size = "100%";
              lvm_type = "raid5";
              extraArgs = [
                "--stripes"
                "3"
              ];
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
