{ config, pkgs, lib, modulesPath, vscode-server, ... }:
{
  config = {
    networking.hostName = "hallewell";

    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" "bcache" "amdgpu" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" "vfio" "vfio_pci" "vfio_iommu_type1" "vfio_virqfd" "amdgpu" ];
    boot.extraModulePackages = [ ];
    boot.kernelParams = [ "intel_iommu=on" "vfio-pci.ids=10de:1c82,10de:0fb9" "pcie_acs_override=downstream,multifunction" ];

    fileSystems."/" =
      {
        device = "/dev/nvme0n1p1:/dev/nvme1n1p1:/dev/sda1:/dev/sdb1";
        fsType = "bcachefs";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-uuid/7B58-56F4";
        fsType = "vfat";
      };

    fileSystems."/mnt/nas" =
      {
        device = "10.69.10.139:/mnt/data0/data";
        fsType = "nfs";
      };

    swapDevices = [ ];

    networking.useDHCP = lib.mkForce false;
    networking.interfaces.eno1.useDHCP = false;
    networking.interfaces.br0.useDHCP = true;

    networking.bridges = {
      "br0" = {
        interfaces = [ "eno1" ];
      };
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    # high-resolution display
    hardware.video.hidpi.enable = lib.mkDefault true;
    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [ (vaapiIntel.override { enableHybridCodec = true; }) vaapiVdpau intel-media-driver libvdpau-va-gl ];
    };
    environment.variables = {
      VDPAU_DRIVER = "va_gl";
    };
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    security.polkit.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
    virtualisation.libvirtd = {
      enable = true;
    };
    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 ramona qemu-libvirtd -"
    ];

    services.home-assistant = {
      enable = true;
      extraComponents = [
        # Components required to complete the onboarding
        "met"
        "radio_browser"
        "deconz"
        "zha"
        "backup"
        "automation"
        "device_automation"
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = { };
        automation = { };
      };
    };

    boot.kernelPatches = [
      {
        name = "add-acs-overrides";
        patch = pkgs.fetchurl {
          name = "add-acs-overrides.patch";
          url =
            "https://aur.archlinux.org/cgit/aur.git/plain/0001-add-acs-overrides.patch?h=linux-vfio&id=33a6d59a36b9cee927c0a648a65b34139c2b3ba1";
          sha256 = "uPl3qpI6pgdnA7iCYuOVxWzp3ylDpSRI2KDjLMkLGnA=";
        };
      }
    ];
  };
}

# 10de:1c82, 10de:0fb9
