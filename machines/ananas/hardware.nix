{pkgsCross}: {
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    boot = {
      initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage"];
      initrd.kernelModules = [];
      kernelModules = [];
      extraModulePackages = [];
      kernelPatches = [
        {
          name = "allow-devmem";
          patch = null;
          extraConfig = ''
            STRICT_DEVMEM n
          '';
        }
      ];
      kernelPackages = lib.mkForce pkgsCross.linuxPackages_latest;
      kernelParams = [];
    };
    fileSystems."/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["relatime"];
    };

    fileSystems."/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = ["relatime"];
    };

    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

    hardware = {
      opengl = {
        enable = true;
      };
      bluetooth.enable = true;

      enableRedistributableFirmware = true;
      deviceTree = {
        enable = true;
        overlays = [
          {
            name = "spi0-0cs.dtbo";
            # this is from https://www.evolware.org/2021/02/21/using-spidev-with-mainline-linux-kernel-on-the-raspberry-pi-4/z, but with patched "compatible"
            dtsText = "
/dts-v1/;
/plugin/;

/{
        compatible = \"brcm,bcm2711\";
        fragment@0 {
                target-path = \"/soc/gpio@7e200000\";
                __overlay__ {
                        spi0_pins: spi0_pins {
                                brcm,pins = <0x09 0x0a 0x0b>;
                                brcm,function = <0x04>;
                                phandle = <0x0d>;
                        };

                        spi0_cs_pins: spi0_cs_pins {
                                brcm,pins = <0x08 0x07>;
                                brcm,function = <0x01>;
                                phandle = <0x0e>;
                        };
        };
    };
        fragment@1 {
                target-path = \"/soc/spi@7e204000\";
                __overlay__ {
             pinctrl-names = \"default\";
             pinctrl-0 = <&spi0_pins &spi0_cs_pins>;
             cs-gpios = <&gpio 8 1>, <&gpio 7 1>;
             status = \"okay\";

             spidev0: spidev@0{
                 compatible = \"lwn,bk4\";
                 reg = <0>;      /* CE0 */
                 #address-cells = <1>;
                 #size-cells = <0>;
                 spi-max-frequency = <125000000>;
             };

             spidev1: spidev@1{
                 compatible = \"lwn,bk4\";
                 reg = <1>;      /* CE1 */
                 #address-cells = <1>;
                 #size-cells = <0>;
                 spi-max-frequency = <125000000>;
             };
                };
        };
};
            ";
          }
        ];
      };
    };

    users.groups.spi = {};
    users.groups.gpio = {};

    services.udev.extraRules = ''
        SUBSYSTEM=="spidev", KERNEL=="spidev0.0", GROUP="spi", MODE="0660"

      SUBSYSTEM=="bcm2835-gpiomem", KERNEL=="gpiomem", GROUP="gpio",MODE="0660"
      SUBSYSTEM=="gpio", KERNEL=="gpiochip*", GROUP="gpio",MODE="0660", ACTION=="add", RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio  /sys/class/gpio/export /sys/class/gpio/unexport ; chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport'"
      SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add",RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value ; chmod 660 /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value'"
    '';

    boot.loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    sound.enable = true;
    sound.extraConfig = ''
      defaults.pcm.card 3
      defaults.ctl.card 3
    '';
  };
}
