{ config, pkgs, lib, ... }:

let
  windowsify = pkgs.writeShellScript "windowsify" ''
    ${pkgs.ddcutil}/bin/ddcutil --sn HRJH2P3 setvcp x60 x1b || true
    ${pkgs.ddcutil}/bin/ddcutil --sn 6MMF1P3 setvcp x60 x0f || true
    ${pkgs.ddcutil}/bin/ddcutil --sn JKPQT83 setvcp x60 x0f || true
    systemctl set-property system.slice AllowedCPUs=22-31
    systemctl set-property user.slice AllowedCPUs=22-31
    systemctl --user --machine ramona@ stop swayidle.service
  '';
  dewindowsify = pkgs.writeShellScript "dewindowsify" ''
    ${pkgs.ddcutil}/bin/ddcutil --sn HRJH2P3 setvcp x60 x0f || true
    ${pkgs.ddcutil}/bin/ddcutil --sn 6MMF1P3 setvcp x60 x11 || true
    ${pkgs.ddcutil}/bin/ddcutil --sn JKPQT83 setvcp x60 x11 || true
    systemctl set-property system.slice AllowedCPUs=0-31
    systemctl set-property user.slice AllowedCPUs=0-31
    systemctl --user --machine ramona@ start swayidle.service
  '';
  bindVfio = pkgs.writeShellScript "bind-vfio" ''
    echo -n "vfio-pci" > /sys/bus/pci/devices/0000:0b:00.0/driver_override
    echo -n "vfio-pci" > /sys/bus/pci/devices/0000:03:00.0/driver_override
    echo -n "vfio-pci" > /sys/bus/pci/devices/0000:03:00.1/driver_override

    modprobe -i vfio-pci
  '';
in
{
  config = {
    boot.kernelParams = [
      "amd_iommu=on"
      # USB card & main GPU
      "vfio-pci.ids=1912:0014,1002:744c,1002:ab30"
      "video=efifb:off,vesafb:off"
      "hugepagesz=1G"
      "hugepages=16"
      "amdgpu.sg_display=0"
    ];
    security.polkit.enable = true;
    security.pam.loginLimits = [
      { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
    ];
    boot.kernel.sysctl = {
      "vm.nr_hugepages" = 9000;
    };
    boot.extraModprobeConfig = ''
      install vfio-pci ${bindVfio}
      options kvm ignore_msrs=1
    '';

    virtualisation.libvirtd = {
      enable = true;
    };

    services.udev.extraRules = ''
      ACTION=="add", ENV{PRODUCT}=="1235/8210/645", RUN+="${dewindowsify}"
      ACTION=="remove", ENV{PRODUCT}=="1235/8210/645", RUN+="${windowsify}"
    '';
  };
}
