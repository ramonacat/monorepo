{
  config,
  lib,
  ...
}: {
  boot = {
    initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "sd_mod" "igb"];
    initrd.kernelModules = [];
    kernelModules = ["kvm-amd"];
    extraModulePackages = [];
    loader.grub.devices = ["/dev/nvme0n1"];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/2e2d43a4-a5ad-46fc-937d-e7c38d146dd1";
    fsType = "bcachefs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/e98b203e-48c9-4e7f-81a7-e173aa785569";
    fsType = "ext4";
  };

  swapDevices = [];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp41s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
