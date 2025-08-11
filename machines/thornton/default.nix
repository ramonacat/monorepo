_: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public
    ../../roles/mysql-server

    ../../users/ramona/installed
    ../../users/root/installed

    ./fleet
    ./nginx

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
