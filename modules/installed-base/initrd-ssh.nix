_: {
  config = {
    boot = {
      kernelParams = ["ip=dhcp"];
      initrd.network = {
        enable = true;
        ssh = {
          enable = true;
          authorizedKeys = let
            sshKeys = import ../../data/ssh-keys.nix;
          in [
            sshKeys.ramona
          ];
          hostKeys = ["/etc/initrd-rsa-hostkey" "/etc/initrd-ed25519-hostkey"];
        };
      };
    };
  };
}
