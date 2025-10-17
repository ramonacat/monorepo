{lib, ...}: {
  config = {
    boot = {
      initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" "bcache" "amdgpu" "e1000e"];
      initrd.kernelModules = [];
      kernelModules = ["kvm-intel" "vfio" "vfio_pci" "vfio_iommu_type1" "vfio_virqfd" "amdgpu" "i2c-dev"];
      kernelParams = ["drm.edid_firmware=edid/1920x1080.bin"];
      extraModulePackages = [];
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };

    powerManagement.powertop.enable = true;
    fileSystems = let
      paths = import ../../data/paths.nix;
    in {
      "/" = {
        device = "/dev/disk/by-uuid/e98a10e4-385b-4c46-a77a-78c1f2a0abdb";
        fsType = "ext4";
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/2620-63CC";
        fsType = "vfat";
      };

      "${paths.hallewell.nas-root}" = {
        device = "/dev/disk/by-uuid/8f552709-24e3-4387-8183-23878c94d00b";
        fsType = "bcachefs";
      };
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = true;
    hardware.graphics = {
      enable = true;
    };
    swapDevices = [
      {
        size = 16 * 1024;
        device = "/swapfile";
      }
    ];
  };
}
