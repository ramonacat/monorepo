{lib, ...}: {
  config = {
    boot = {
      initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" "bcache" "amdgpu"];
      initrd.kernelModules = [];
      kernelModules = ["kvm-intel" "vfio" "vfio_pci" "vfio_iommu_type1" "vfio_virqfd" "amdgpu" "i2c-dev"];
      kernelParams = ["systemd.setenv=SYSTEMD_SULOGIN_FORCE=1"];
      extraModulePackages = [];
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };

    powerManagement.powertop.enable = true;
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/e98a10e4-385b-4c46-a77a-78c1f2a0abdb";
        fsType = "ext4";
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/2620-63CC";
        fsType = "vfat";
      };

      "/mnt/nas3" = {
        device = "/dev/disk/by-uuid/8f552709-24e3-4387-8183-23878c94d00b";
        fsType = "bcachefs";
        noCheck = true;
        neededForBoot = false;
      };
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = true;
    hardware.graphics = {
      enable = true;
    };
  };
}
