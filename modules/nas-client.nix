{...}: {
  config = {
    fileSystems."/mnt/nas" = {
      device = "hallewell:/mnt/nas3/data";
      fsType = "nfs";
      options = ["x-systemd.after=tailscaled.service"];
    };
  };
}
