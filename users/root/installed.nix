{config, ...}: {
  imports = [
    ./base.nix
  ];
  config = {
    age.secrets.root-password = {
      file = ../../secrets/root-password.age;
    };

    users.users.root = {
      hashedPasswordFile = config.age.secrets.root-password.path;
    };
  };
}
