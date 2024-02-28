{ config, pkgs, lib, ... }:
{
  config = {
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" "bcache" "amdgpu" ];
    boot.initrd.kernelModules = [ "vfio_pci " ];
    boot.kernelModules = [ "kvm-amd" "vfio" "vfio_pci" "vfio_iommu_type1" "vfio_virqfd" "amdgpu" "i2c-dev" ];
    boot.extraModulePackages = [ ];
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    programs.adb.enable = true;
    fileSystems."/" =
      {
        device = "/dev/disk/by-uuid/aed4868d-65c0-446e-8d2b-22929c9ee46b";
        fsType = "ext4";
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

    hardware.openrazer.enable = true;

    services.pipewire.extraConfig.pipewire = {
      "99-roc-sink" = lib.mkForce {
        "context.modules" = [{
          "name" = "libpipewire-module-roc-source";
          "args" = {
            "local.ip" = "0.0.0.0";
            "resampler.profile" = "medium";
            "fec.code" = "rs8m";
            "ses.latency.msec" = 5000;
            "local.source.port" = 10001;
            "local.repair.port" = 10002;
            "local.control.port" = 10003;
            "source.name" = "ROC source";
            "source.props" = {
              "node.name" = "roc-source";
            };
          };
        }];
      };
    };
  };
}
