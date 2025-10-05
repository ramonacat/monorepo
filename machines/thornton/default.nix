_: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public

    ./networking.nix
    ./postgresql.nix
    ./minio.nix
    ./telegraf.nix
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
