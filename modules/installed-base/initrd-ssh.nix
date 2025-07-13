_: {
  config = {
    age.secrets.hostkey-rsa-initrd = {
      file = ../../secrets/hostkey-rsa-initrd.age;
      path = "/etc/initrd-rsa-hostkey";
      symlink = false;
    };
    age.secrets.hostkey-ed25519-initrd = {
      file = ../../secrets/hostkey-ed25519-initrd.age;
      path = "/etc/initrd-ed25519-hostkey";
      symlink = false;
    };
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
