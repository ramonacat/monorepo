{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-amd"];
    boot.extraModulePackages = [];
    services.fwupd.enable = false;
    boot.binfmt.emulatedSystems = ["aarch64-linux"];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = true;

    fileSystems."/" = {
      device = "/dev/nvme0n1p2:/dev/nvme1n1p1";
      fsType = "bcachefs";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "ext2";
    };

    boot.loader.grub = {
      enable = true;
      devices = ["/dev/nvme0n1"];
    };
  };
}
