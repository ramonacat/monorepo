{lib, ...}: {
  config = {
    boot = {
      initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" "bcache" "amdgpu"];
      initrd.kernelModules = [];
      kernelModules = ["kvm-intel" "vfio" "vfio_pci" "vfio_iommu_type1" "vfio_virqfd" "amdgpu" "i2c-dev"];
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
        device = "/dev/disk/by-id/wwn-0x5000cca2a0c551c7:/dev/disk/by-id/wwn-0x5000cca296c1680c:/dev/disk/by-id/nvme-eui.0025385191b0bc29:/dev/disk/by-id/:/dev/disk/by-id/nvme-eui.0025385a81b20689:/dev/disk/by-id/wwn-0x5002538043584d30:/dev/disk/by-id/wwn-0x5002538e40c8552a:/dev/disk/by-id/wwn-0x5002538e40c8526c:/dev/disk/by-id/wwn-0x5000cca2a0c5632b:/dev/disk/by-id/wwn-0x5000cca2eec47ea2";
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
