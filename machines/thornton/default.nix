_: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public

    ./nginx

    ./grafana.nix
    ./minio.nix
    ./networking.nix
    ./postgresql.nix
    ./ras2.nix
    ./ras2.nix
    ./telegraf.nix
    ./tempo.nix
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
