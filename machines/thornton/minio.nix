{config, ...}: {
  config = let
    minio-port = 9000;
    minio-webui-port = 9000;
  in {
    age.secrets.minio-root = {
      file = ../../secrets/minio-root.age;
      group = "minio";
      mode = "440";
    };

    services.minio = {
      enable = true;
      dataDir = ["/var/lib/minio/"];
      rootCredentialsFile = config.age.secrets.minio-root.path;
      listenAddress = ":${builtins.toString minio-port}";
      consoleAddress = ":${builtins.toString minio-webui-port}";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [minio-port minio-webui-port];
  };
}
