{lib, ...}: {
  config = {
    boot = {
      initrd = {
        availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod"];
        kernelModules = [];
        systemd = {
          enable = true;
          enableTpm2 = true;
        };
        luks.devices = {
          luksroot = {
            device = "/dev/disk/by-uuid/12dcdb50-cc70-4134-a7cb-ef17b34e981d";
            preLVM = true;
            allowDiscards = true;
          };
        };
      };
      kernelModules = ["kvm-amd"];
      extraModulePackages = [];
      kernelParams = ["amd_pstate=active"];
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/9c39d5fb-30e2-4569-be17-6f6475630c29";
      fsType = "bcachefs";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/98C8-63DA";
      fsType = "vfat";
    };
    swapDevices = [
      {device = "/dev/disk/by-uuid/e0a4b913-594c-4810-b690-e35e1f4f87b0";}
    ];

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
