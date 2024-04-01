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
      };
      kernelModules = ["kvm-intel"];
      extraModulePackages = [];
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/a4e7280f-6a38-458a-befc-3666b8dd418f";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/21CD-8A5D";
      fsType = "vfat";
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/833d74db-81f7-4661-ac76-972b2748d5d0";}
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
