{config, ...}: {
  imports = [
    ../base
  ];
  config = {
    age.secrets =
      if config.ramona.machine.hasPublicIP
      then {
        user-password-public-ramona = {
          file = ../../../secrets/user-password-public-ramona.age;
        };
      }
      else {
        user-password-private-ramona = {
          file = ../../../secrets/user-password-private-ramona.age;
        };
      };

    users.users.ramona = {
      hashedPasswordFile =
        if config.ramona.machine.hasPublicIP
        then config.age.secrets.user-password-public-ramona.path
        else config.age.secrets.user-password-private-ramona.path;
    };
  };
}
