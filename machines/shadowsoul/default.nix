_: {
  imports = [
    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private
    ../../roles/builds-host

    ../../users/ramona/installed
    ../../users/root/installed

    ./github-runner.nix
    ./hardware.nix
    ./networking.nix
    ./transmission.nix
  ];
}
