{config, ...}: {
  imports = [
    ./base.nix
  ];
  config = {
    age.secrets.ramona-password = {
      file = ../../secrets/ramona-password.age;
    };

    users.users.ramona = {
      hashedPasswordFile = config.age.secrets.ramona-password.path;
    };
  };
}
