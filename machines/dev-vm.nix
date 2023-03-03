{ config, pkgs, lib, modulesPath, vscode-server, ...}:
  {    
    config = {
      boot.initrd.availableKernelModules = [ "ata_piix" "mptspi" "uhci_hcd" "ehci_pci" "xhci_pci" "sd_mod" "sr_mod" ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/14907592-83ac-45be-8a89-a4be82838a3e";
        fsType = "ext4";
      };

      boot.loader.grub.enable = true;
      boot.loader.grub.device = "/dev/sda";

      networking.hostName = "ramona-dev-vm";
      networking.networkmanager.enable = true;

      networking.interfaces.ens34.ipv4.addresses = [ { address = "192.168.42.2"; prefixLength = 24; } ];

      services.getty.autologinUser = "ramona";

      virtualisation.vmware.guest.enable = true;

      networking.firewall.enable = false;
    };
  }
 