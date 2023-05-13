{ config, pkgs, lib, ... }:
{
  config = {
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" "bcache" "amdgpu" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" "vfio" "vfio_pci" "vfio_iommu_type1" "vfio_virqfd" "amdgpu" "i2c-dev" ];
    boot.extraModulePackages = [ ];
    fileSystems."/" =
      {
        device = "/dev/nvme0n1p2:/dev/nvme1n1p2:/dev/nvme2n1p2";
        fsType = "bcachefs";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-uuid/11F1-94F3";
        fsType = "vfat";
      };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
    hardware.cpu.amd.updateMicrocode = true;
    hardware.opengl = {
      enable = true;
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
