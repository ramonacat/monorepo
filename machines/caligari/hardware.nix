{lib, ...}: {
  config = {
    boot = {
      initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid"];
      initrd.kernelModules = [];
      kernelModules = ["kvm-amd"];
      extraModulePackages = [];
      binfmt.emulatedSystems = ["aarch64-linux"];

      loader.grub = {
        enable = true;
        devices = ["/dev/nvme0n1"];
      };
    };
    services.fwupd.enable = false;
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
  };
}
