{
  lib,
  config,
  ...
}: {
  config = {
    boot = {
      initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "rtsx_usb_sdmmc" "e1000e" "igb"];
      initrd.kernelModules = [];
      kernelModules = ["kvm-intel"];
      extraModulePackages = [];
    };
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/a1d31050-d300-425c-bf6b-bfd8ba9039f2";
        fsType = "bcachefs";
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/A408-FCA2";
        fsType = "vfat";
      };

      "/var/lib/transmission/Downloads/sonarr" = {
        device = "192.168.2.69:/mnt/storage/Agares";
        fsType = "nfs";
        options = ["x-systemd.required-by=transmission.service" "x-systemd.required-by=syncthing.service"];
      };
    };

    swapDevices = [{device = "/dev/disk/by-uuid/f968be24-cead-4d7f-9f7e-f9a7646a9a39";}];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
