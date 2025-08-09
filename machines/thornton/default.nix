_: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public
    ../../roles/builds-host

    ../../users/ramona/installed
    ../../users/root/installed

    ./github-runner.nix
    ./networking.nix
  ];
  config = {
    swapDevices = [
      {
        size = 8192;
        device = "/swapfile";
      }
    ];
  };
}
