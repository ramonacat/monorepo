{ config, pkgs, lib, ... }:
{
  config = {
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" "bcache" "amdgpu" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" "vfio" "vfio_pci" "vfio_iommu_type1" "vfio_virqfd" "amdgpu" "i2c-dev" ];
    boot.extraModulePackages = [ ];
    fileSystems."/" =
      {
        device = "/dev/disk/by-uuid/e98a10e4-385b-4c46-a77a-78c1f2a0abdb";
        fsType = "ext4";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-uuid/2620-63CC";
        fsType = "vfat";
      };

    fileSystems."/mnt/nas3" = {
      device = "/dev/disk/by-id/wwn-0x5002538e40c8526c:/dev/disk/by-id/wwn-0x5002538e40c8552a:/dev/disk/by-id/wwn-0x50014ee2bea74c42:/dev/disk/by-id/wwn-0x50014ee213fbb2bb:/dev/disk/by-id/wwn-0x5002538043584d30:/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_250GB_S465NX0KA04299B:/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_250GB_S465NX0M104145D";
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
c