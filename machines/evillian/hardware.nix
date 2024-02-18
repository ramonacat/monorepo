{ config, pkgs, lib, ... }:
{
  config = {
    powerManagement.powertop.enable = true;
    services.upower.enable = true;
    boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];
    fileSystems."/" =
      {
        device = "/dev/disk/by-uuid/d991d608-ce53-4995-9414-3c981c0e550e";
        fsType = "ext4";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-uuid/A3FA-597D";
        fsType = "vfat";
      };
    swapDevices = [{ device = "/dev/disk/by-uuid/b616878a-7677-4844-b81c-b11f7ae1421c"; }];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = true;
    hardware.opengl = {
      enable = true;
    };
    hardware.pulseaudio.enable = false;
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    systemd.services.lte_modem_fix =
      let
        modemFixScript = pkgs.writeScriptBin "fix_lte_modem" ''
          #!${pkgs.stdenv.shell}

          echo -n 16383 > /sys/bus/usb/devices/2-3:1.0/net/wwp0s20f0u3/cdc_ncm/rx_max
          echo -n 16383 > /sys/bus/usb/devices/2-3:1.0/net/wwp0s20f0u3/cdc_ncm/tx_max

          echo -n 16384 > /sys/bus/usb/devices/2-3:1.0/net/wwp0s20f0u3/cdc_ncm/rx_max
          echo -n 16384 > /sys/bus/usb/devices/2-3:1.0/net/wwp0s20f0u3/cdc_ncm/tx_max
        '';
      in
      {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${modemFixScript}/bin/fix_lte_modem";
        };
      };
  };
}
