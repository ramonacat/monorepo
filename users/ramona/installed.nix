{config, ...}: {
  imports = [
    ./base.nix
  ];
  config = {
    age.secrets.ramona-password = {
      file = ../../secrets/ramona-password.age;
    };
    age.secrets.lix-repo-credentials = {
      file = ../../secrets/lix-repo-credentials.age;
      owner = "ramona";
    };

    home-manager.users.ramona.programs.git.extraConfig = {
      credential = {
        "https://git.lix.systems" = {
          username = "ramona";
          helper = "!f() { test \"$1\" = get && echo \"password=$(cat ${config.age.secrets.lix-repo-credentials.path})\"; }; f";
        };
      };
    };

    users.users.ramona = {
      hashedPasswordFile = config.age.secrets.ramona-password.path;
    };
  };
}
