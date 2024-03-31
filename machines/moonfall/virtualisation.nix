{pkgs, ...}: let
  windowsify = pkgs.writeShellScript "windowsify" ''
    systemctl set-property system.slice AllowedCPUs=22-31
    systemctl set-property user.slice AllowedCPUs=22-31
    systemctl --user --machine ramona@ stop swayidle.service
  '';
  dewindowsify = pkgs.writeShellScript "dewindowsify" ''
    systemctl set-property system.slice AllowedCPUs=0-31
    systemctl set-property user.slice AllowedCPUs=0-31
    systemctl --user --machine ramona@ start swayidle.service
  '';
  bindVfio = pkgs.writeShellScript "bind-vfio" ''
    echo -n "vfio-pci" > /sys/bus/pci/devices/0000:07:00.0/driver_override # USB controller
    echo -n "vfio-pci" > /sys/bus/pci/devices/0000:03:00.0/driver_override # GPU
    echo -n "vfio-pci" > /sys/bus/pci/devices/0000:03:00.1/driver_override # GPU

    modprobe -i vfio-pci
  '';
in {
  config = {
    boot.kernelParams = [
      "amd_iommu=on"
      # USB card & main GPU
      "vfio-pci.ids=1b21:2142,1002:744c,1002:ab30"
      "video=efifb:off,vesafb:off"
      "hugepagesz=1G"
      "hugepages=16"
      "amdgpu.sg_display=0"
    ];
    security.polkit.enable = true;
    security.pam.loginLimits = [
      {
        domain = "*";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
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

    systemd.services.windowsify = {
      description = "make this machine windowsy";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${windowsify}";
      };
    };

    systemd.services.dewindowsify = {
      description = "make this machine not windowsy";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${dewindowsify}";
      };
    };

    services.udev.extraRules = ''
      ACTION=="add", ATTRS{idVendor}=="1235", ATTRS{idProduct}=="8210", RUN+="${pkgs.systemd}/bin/systemctl start dewindowsify"
      ACTION=="remove", ENV{PRODUCT}=="1235/8210/645", RUN+="${pkgs.systemd}/bin/systemctl start windowsify"
    '';

    systemd.services.permissions-looking-glass = {
      description = "Set permissions for looking glass shm file";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/chown ramona:kvm /dev/shm/looking-glass";
      };
    };

    systemd.timers.permissions-looking-glass = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "1m";
        Unit = "permissions-looking-glass.service";
      };
    };
  };
}
