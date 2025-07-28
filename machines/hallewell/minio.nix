{config, ...}: {
  config = let
    minio-port = 9000;
  in {
    age.secrets.minio-root = {
      file = ../../secrets/minio-root.age;
      group = "minio";
      mode = "440";
    };

    services.minio = let
      paths = import ../../data/paths.nix;
    in {
      enable = true;
      dataDir = ["${paths.hallewell.nas-root}/minio/"];
      rootCredentialsFile = config.age.secrets.minio-root.path;
      listenAddress = ":${builtins.toString minio-port}";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [minio-port];
  };
}
