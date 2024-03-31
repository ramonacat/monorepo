{lib, ...}: {
  config = {
    boot = {
      initrd.availableKernelModules = ["xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "rtsx_usb_sdmmc" "bcache"];
      initrd.kernelModules = [];
      kernelModules = ["kvm-intel" "i2c-dev"];
      extraModulePackages = [];
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };
    services.logind.lidSwitch = "ignore";
    fileSystems."/" = {
      device = "/dev/sdb1:/dev/sda1";
      fsType = "bcachefs";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/D119-17DB";
      fsType = "vfat";
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
    hardware = {
      cpu.intel.updateMicrocode = true;
      opengl = {
        enable = true;
      };
      bluetooth.enable = true;
    };
  };
}
