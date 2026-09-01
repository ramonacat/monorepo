{
  lib,
  config,
  ...
}:
{
  config = {
    boot = {
      initrd = {
        availableKernelModules = [
          "xhci_pci"
          "ahci"
          "nvme"
          "usbhid"
          "usb_storage"
          "sd_mod"
          "rtsx_usb_sdmmc"
          "e1000e"
          "igb"
        ];
        kernelModules = [ ];
      };

      kernelModules = [ "kvm-intel" ];
      extraModulePackages = [ ];
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/4459e4d3-51f6-4b1f-b074-31a163a89a61";
        fsType = "bcachefs";
        options = [
          "x-systemd.wants=/dev/sda"
          "x.systemd.wants=/dev/nvme0n1"
        ];
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/A8D3-4F6D";
        fsType = "vfat";
      };

      "/var/lib/transmission/Downloads/sonarr" = {
        device = "192.168.2.69:/mnt/storage/Agares";
        fsType = "nfs";
        options = [
          "x-systemd.required-by=transmission.service"
          "x-systemd.required-by=syncthing.service"
        ];
      };
    };

    swapDevices = [ { device = "/dev/disk/by-uuid/993d84ac-5dd2-408d-b3d3-74b667b989a3"; } ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
