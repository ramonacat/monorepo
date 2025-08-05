{config, ...}: {
  imports = [
    ./base.nix
  ];
  config = {
    age.secrets =
      if config.ramona.machine.hasPublicIP
      then {
        user-password-public-root = {
          file = ../../secrets/user-password-public-root.age;
        };
      }
      else {
        user-password-private-root = {
          file = ../../secrets/user-password-private-root.age;
        };
      };

    users.users.root = {
      hashedPasswordFile =
        if config.ramona.machine.hasPublicIP
        then config.age.secrets.user-password-public-root.path
        else config.age.secrets.user-password-private-root.path;
    };
  };
}
