_: {
  config = let
    paths = import ../../../data/paths.nix;
  in {
    fileSystems."/mnt/nas" = {
      device = "hallewell:${paths.hallewell.nas-share}";
      fsType = "nfs";
      options = ["x-systemd.after=tailscaled.service"];
    };
    ramona.machine.roles = ["nas-client"];
  };
}
