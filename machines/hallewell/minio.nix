{config, ...}: {
  config = {
    age.secrets.minio-root = {
      file = ../../secrets/minio-root.age;
      group = "minio";
      mode = "440";
    };

    services.minio = {
      enable = true;
      dataDir = ["/mnt/nas3/minio/"];
      rootCredentialsFile = config.age.secrets.minio-root.path;
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [9000];
  };
}
