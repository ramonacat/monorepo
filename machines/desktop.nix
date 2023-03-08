{ config, pkgs, lib, modulesPath, vscode-server, ... }:
{
  config = {
    networking.hostName = "hallewell";

    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" "bcache" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" "vfio" "vfio_pci" "vfio_iommu_type1" "vfio_virqfd" ];
    boot.extraModulePackages = [ ];
    boot.kernelParams = [ "intel_iommu=on" "vfio-pci.ids=10de:1c82,10de:0fb9" ];

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

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    # networking.useDHCP = lib.mkDefault true;
    networking.interfaces.eno1.useDHCP = lib.mkForce false;

    networking.bridges = {
      "br0" = {
        interfaces = [ "eno1" ];
      };
    };
    networking.interfaces.br0.ipv4.addresses = [
      { address = "10.69.10.5"; prefixLength = 24; }
    ];
    networking.defaultGateway = "10.69.10.1";
    networking.nameservers = [ "8.8.8.8" ];

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

    # users.extraUsers.hass = {
    #   extraGroups = [ "dialout" "tty" ];
    # };

    # services.udev.extraRules = ''
    #   KERNEL=="ttyACM0", TAG+="udev-acl", TAG+="uaccess", OWNER="hass"
    # '';


    services.home-assistant = {
      enable = true;
      extraComponents = [
        # Components required to complete the onboarding
        "met"
        "radio_browser"
        "deconz"
        "zha"
        "backup"
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = { };
      };
    };
  };
}

# 10de:1c82, 10de:0fb9
