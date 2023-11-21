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
          # this is from https://github.com/raspberrypi/linux/blob/5a0aa24b8ff58ceaf98c62670156bef7f48ed32b/arch/arm/boot/dts/overlays/spi0-0cs-overlay.dts, but with patched "compatible"
          dtsText = "
            /dts-v1/;
            /plugin/;

            / {
              compatible = \"brcm\";

              fragment@0 {
                target = <&spi0_cs_pins>;
                frag0: __overlay__ {
                  brcm,pins;
                };
              };

              fragment@1 {
                target = <&spi0>;
                __overlay__ {
                  cs-gpios;
                  status = \"okay\";
                };
              };

              fragment@2 {
                target = <&spidev1>;
                __overlay__ {
                  status = \"disabled\";
                };
              };

              fragment@3 {
                target = <&spi0_pins>;
                __dormant__ {
                  brcm,pins = <10 11>;
                };
              };

              __overrides__ {
                no_miso = <0>,\"=3\";
              };
            };
            ";
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
