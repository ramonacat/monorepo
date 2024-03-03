{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-amd"];
    boot.extraModulePackages = [];
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/08243e9b-e1e5-494d-8c9b-0b1675541061";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/8D20-2ED2";
      fsType = "vfat";
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = true;
    powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
    hardware.sensor.iio.enable = true;

    boot.kernelParams = ["amd_pstate=active"];
    hardware.opengl = {
      enable = true;
    };
    hardware.bluetooth.enable = true;

    hardware.bluetooth.settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
    services.blueman.enable = true;
    services.fprintd.enable = true;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    services.power-profiles-daemon.enable = true;
    powerManagement.powertop.enable = true;
    services.upower.enable = true;

    services.logind.lidSwitchDocked = "ignore";
  };
}
