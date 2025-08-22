{config, ...}: {
  imports = [
    ../tailscale-nginx

    ./nginx

    ./serve.nix
  ];
  config = {
    age.secrets.nix-serve-key = {file = ../../secrets/nix-serve-key.age;};
    ramona.machine.roles = ["builds-host"];

    users.users.root.openssh.authorizedKeys.keys = [
      (import ../../data/ssh-keys.nix).root.ci
    ];

    nix.settings.secret-key-files = [config.age.secrets.nix-serve-key.path];
  };
}
