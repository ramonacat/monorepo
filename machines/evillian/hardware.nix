{
  pkgs,
  lib,
  ...
}: {
  config = {
    powerManagement.powertop.enable = true;
    services.upower.enable = true;
    boot = {
      initrd = {
        availableKernelModules = ["xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc"];
        kernelModules = [];
        systemd = {
          enable = true;
          enableTpm2 = true;
        };
        luks.devices = {
          luksroot = {
            device = "/dev/disk/by-uuid/145b1be2-ee92-487b-80e9-1e744b5ec5d6";
            preLVM = true;
            allowDiscards = true;
          };
        };
      };
      lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
      };
      kernelModules = ["kvm-intel"];
      extraModulePackages = [];
      loader.systemd-boot.enable = false; # lanzaboote does it's magic instead
      loader.efi.canTouchEfiVariables = true;
    };
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/fcaeec1c-1e4f-423a-b8aa-5d871bc17cb2";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/4B8C-0DB9";
      fsType = "vfat";
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/37bcd061-33bb-4632-b465-3aaff73a45f4";}
    ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware = {
      cpu.intel.updateMicrocode = true;
      opengl = {
        enable = true;
      };
      pulseaudio.enable = false;
    };

    systemd.services.lte_modem_fix = let
      modemFixScript = pkgs.writeScriptBin "fix_lte_modem" ''
        #!${pkgs.stdenv.shell}

        echo -n 16383 > /sys/bus/usb/devices/2-3:1.0/net/wwp0s20f0u3/cdc_ncm/rx_max
        echo -n 16383 > /sys/bus/usb/devices/2-3:1.0/net/wwp0s20f0u3/cdc_ncm/tx_max

        echo -n 16384 > /sys/bus/usb/devices/2-3:1.0/net/wwp0s20f0u3/cdc_ncm/rx_max
        echo -n 16384 > /sys/bus/usb/devices/2-3:1.0/net/wwp0s20f0u3/cdc_ncm/tx_max
      '';
    in {
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${modemFixScript}/bin/fix_lte_modem";
      };
    };
    systemd.services.ModemManager.wantedBy = ["multi-user.target"];
  };
}
