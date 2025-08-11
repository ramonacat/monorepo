_: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public

    ../../users/ramona/installed
    ../../users/root/installed

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
