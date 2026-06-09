_: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public

    ./nginx
    ./networking.nix
  ];
  config = {
    users.users.root.openssh.authorizedKeys.keys = [
      (import ../../data/ssh-keys.nix).root.ci
    ];
  };
}
