{
  lib,
  config,
  ...
}: {
  config = let
    paths = import ../../data/paths.nix;
  in {
    fileSystems."/mnt/nas" = lib.mkIf (config.networking.hostName != "hallewell") {
      device = "hallewell:${paths.hallewell.nas-share}";
      fsType = "nfs";
      options = ["x-systemd.after=tailscaled.service"];
    };
  };
}
