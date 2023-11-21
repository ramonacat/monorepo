{ config, pkgs, lib, ... }:
{
  config = {
    boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];
    boot.kernelPackages = pkgs.linuxPackages_latest;
    fileSystems."/" =
      {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
        options = [ "relatime" ];
      };

    fileSystems."/boot/firmware" =
      {
        device = "/dev/disk/by-label/FIRMWARE";
        fsType = "vfat";
        options = [ "relatime" ];
      };

    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

    boot.kernelParams = [ ];
    hardware.opengl = {
      enable = true;
    };
    hardware.bluetooth.enable = true;

    hardware.enableRedistributableFirmware = true;
    hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    hardware.deviceTree = {
      enable = true;
      filter = "*-rpi-4-*.dtb";
      overlays = [
        {
          name = "spi0-0cs.dtbo";
          # this is from https://github.com/raspberrypi/firmware/blob/master/boot/overlays/spi0-0cs.dtbo, but with patched "compatible"
          dtsText = "
            /dts-v1/;
            / {
              compatible = \"brcm\";

              fragment@0 {
                target = <0xffffffff>;

                __overlay__ {
                  brcm,pins;
                  phandle = <0x01>;
                };
              };

              fragment@1 {
                target = <0xffffffff>;

                __overlay__ {
                  cs-gpios;
                  status = \"okay\";
                };
              };

              fragment@2 {
                target = <0xffffffff>;

                __overlay__ {
                  status = \"disabled\";
                };
              };

              fragment@3 {
                target = <0xffffffff>;

                __dormant__ {
                  brcm,pins = <0x0a 0x0b>;
                };
              };

              __overrides__ {
                no_miso = [00 00 00 00 3d 33 00];
              };

              __symbols__ {
                frag0 = \"/fragment@0/__overlay__\";
              };

              __fixups__ {
                spi0_cs_pins = \"/fragment@0:target:0\";
                spi0 = \"/fragment@1:target:0\";
                spidev1 = \"/fragment@2:target:0\";
                spi0_pins = \"/fragment@3:target:0\";
              };
            };";
        }
      ];
    };

    users.groups.spi = { };

    services.udev.extraRules = ''
      SUBSYSTEM=="spidev", KERNEL=="spidev0.0", GROUP="spi", MODE="0660"
    '';


    boot.loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };
}
