_: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public

    ./grafana.nix
    ./minio.nix
    ./networking.nix
    ./postgresql.nix
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
