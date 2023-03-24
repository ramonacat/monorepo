{ config, pkgs, lib, ... }:
{
  config = {
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" "bcache" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" "vfio" "vfio_pci" "vfio_iommu_type1" "vfio_virqfd" "amdgpu" "i2c-dev" ];
    boot.extraModulePackages = [ ];
    boot.kernelParams = [
      # this is needed for iotop
      "delayacct"
    ];
    fileSystems."/" =
      {
        device = "/dev/nvme0n1p1:/dev/nvme1n1p1:/dev/sda1:/dev/sdb1";
        fsType = "bcachefs";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-uuid/7B58-56F4";
        fsType = "vfat";
      };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
    hardware.cpu.intel.updateMicrocode = true;
    hardware.opengl = {
      enable = true;
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
