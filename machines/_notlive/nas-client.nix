{
  lib,
  config,
  ...
}: {
  config = {
    fileSystems."/mnt/nas" = lib.mkIf (config.networking.hostName != "hallewell") {
      device = "hallewell:/mnt/nas3/data";
      fsType = "nfs";
      options = ["x-systemd.after=tailscaled.service"];
    };
  };
}
