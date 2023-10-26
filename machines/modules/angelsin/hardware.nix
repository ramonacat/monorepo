{ config, pkgs, lib, ... }:
{
  config = {
    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];
    fileSystems."/" =
      {
        device = "/dev/disk/by-uuid/08243e9b-e1e5-494d-8c9b-0b1675541061";
        fsType = "ext4";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-uuid/8D20-2ED2";
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
