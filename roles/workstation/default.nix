{config, ...}: {
  imports = [
    ../../modules/machine-kind.nix
  ];
  config = {
    age.secrets.wireless-passwords = {
      file = ../../secrets/wireless-passwords.age;
    };
    ramona.machine = {
      type = "workstation";
      hasPublicIP = false;
    };
    networking.wireless = {
      enable = true;
      secretsFile = config.age.secrets.wireless-passwords.path;
      networks = {
        Savares = {
          pskRaw = "ext:Savares";
          priority = 1000;
        };
        graves.pskRaw = "ext:graves";
      };
    };
  };
}
