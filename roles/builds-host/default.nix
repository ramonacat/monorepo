_: {
  imports = [
    ../tailscale-nginx

    ./nginx

    ./nix-serve.nix
  ];
  config = {
    ramona.machine.roles = ["builds-host"];

    users.users.root.openssh.authorizedKeys.keys = [
      (import ../../data/ssh-keys.nix).root.ci
    ];
  };
}
