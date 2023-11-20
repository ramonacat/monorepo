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
    hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    hardware.deviceTree = {
      enable = true;
      filter = "*-rpi-*.dtb";
      overlays = [
        { name = "spi0-0cs.dtbo"; dtboFile = "${pkgs.device-tree_rpi.overlays}/spi0-0cs.dtbo"; }
      ];
    };

    users.groups.spi = {};

    services.udev.extraRules = ''
      SUBSYSTEM=="spidev", KERNEL=="spidev0.0", GROUP="spi", MODE="0660"
    '';


    boot.loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };
}
