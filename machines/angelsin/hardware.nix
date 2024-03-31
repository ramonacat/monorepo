{lib, ...}: {
  config = {
    boot = {
      initrd.availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod"];
      initrd.kernelModules = [];
      kernelModules = ["kvm-amd"];
      extraModulePackages = [];
      kernelParams = ["amd_pstate=active"];
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/08243e9b-e1e5-494d-8c9b-0b1675541061";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/8D20-2ED2";
      fsType = "vfat";
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware = {
      cpu.amd.updateMicrocode = true;
      sensor.iio.enable = true;
      opengl = {
        enable = true;
      };
      bluetooth.enable = true;

      bluetooth.settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
    powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

    services = {
      blueman.enable = true;
      fprintd.enable = true;
      power-profiles-daemon.enable = true;
      upower.enable = true;
    };

    powerManagement.powertop.enable = true;

    services.logind.lidSwitchDocked = "ignore";
  };
}
