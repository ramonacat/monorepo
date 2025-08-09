_: {
  config = {
    boot = {
      loader = {
        grub.enable = false;
        systemd-boot = {
          enable = true;
          editor = false;
        };
        efi.canTouchEfiVariables = true;
      };
      initrd = {
        luks.devices = {
          cryptroot = {
            device = "/dev/disk/by-uuid/c6104151-4b5e-40b3-af13-b69c30c41de";
            crypttabExtraOpts = ["tpm2-device=auto"];
          };
        };
        availableKernelModules = [
          "tpm_tis"
          "aes_generic"
          "cryptd"
        ];
      };
    };

    # This is needed, because we're dual booting with windows, which uses local time
    time.hardwareClockInLocalTime = true;
    hardware.graphics = {
      enable = true;
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/16ba2130-302a-410a-afc5-c130a8902bc2";
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/F829-D65D";
        fsType = "vfat";
      };
    };
  };
}
