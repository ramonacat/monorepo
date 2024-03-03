{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" "bcache" "amdgpu"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-intel" "vfio" "vfio_pci" "vfio_iommu_type1" "vfio_virqfd" "amdgpu" "i2c-dev"];
    boot.extraModulePackages = [];
    powerManagement.powertop.enable = true;
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/e98a10e4-385b-4c46-a77a-78c1f2a0abdb";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/2620-63CC";
      fsType = "vfat";
    };

    fileSystems."/mnt/nas3" = {
      device = "UUID=8f552709-24e3-4387-8183-23878c94d00b";
      fsType = "bcachefs";
      noCheck = true;
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = true;
    hardware.opengl = {
      enable = true;
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
