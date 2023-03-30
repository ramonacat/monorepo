{ config, pkgs, lib, ... }:

let
  windowsify = pkgs.writeShellScript "windowsify" ''
    ${pkgs.ddcutil}/bin/ddcutil --sn 7MT0186418CU setvcp x60 x10 || true
    ${pkgs.ddcutil}/bin/ddcutil --sn XKV0P9C334FS setvcp x60 x12 || true
  '';
  dewindowsify = pkgs.writeShellScript "dewindowsify" ''
    ${pkgs.ddcutil}/bin/ddcutil --sn 7MT0186418CU setvcp x60 x0f || true
    ${pkgs.ddcutil}/bin/ddcutil --sn XKV0P9C334FS setvcp x60 x11 || true
  '';
in
{
  config = {
    boot.initrd.availableKernelModules = [ "amdgpu" ];
    boot.kernelParams = [
      "intel_iommu=on"
      # first two are GPU, the third is USB card
      "vfio-pci.ids=10de:1c82,10de:0fb9,1912:0014"
      # This is an evil dangerous hack, but I accept the risk
      "pcie_acs_override=downstream,multifunction"
    ];
    security.polkit.enable = true;
    security.pam.loginLimits = [
      { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
    ];
    boot.kernel.sysctl = {
      "vm.nr_hugepages" = 8192;
      #    "vm.hugetlb_shm_group" = 36;
    };

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

    services.udev.extraRules = ''
      ACTION=="add", ENV{PRODUCT}=="1235/8210/645", RUN+="${dewindowsify}"
      ACTION=="remove", ENV{PRODUCT}=="1235/8210/645", RUN+="${windowsify}"
    '';
  };
}
