{ config, pkgs, lib, ... }:
{
  config = {
    boot.initrd.availableKernelModules = [ "amdgpu" ];
    boot.kernelParams = [
      "intel_iommu=on"
      "vfio-pci.ids=10de:1c82,10de:0fb9"
      "pcie_acs_override=downstream,multifunction"
      # This prevents USB devices sleeping which can make them reset when passed through
      "usbcore.autosuspend=-1"
    ];
    security.polkit.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
    virtualisation.libvirtd = {
      enable = true;
    };
    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 ramona qemu-libvirtd -"
    ];

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
