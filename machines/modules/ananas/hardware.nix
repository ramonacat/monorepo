{ config, pkgs, lib, ... }:
{
  config = {
    boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];
    boot.kernelPackages = pkgs.linuxPackages_latest;
    fileSystems."/" =
      {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
        options = [ "relatime" ];
      };

    fileSystems."/boot/firmware" =
      {
        device = "/dev/disk/by-label/FIRMWARE";
        fsType = "vfat";
        options = [ "relatime" ];
      };

    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

    boot.kernelParams = [ ];
    hardware.opengl = {
      enable = true;
    };
    hardware.bluetooth.enable = true;

    hardware.enableRedistributableFirmware = true;

    boot.loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };
}
