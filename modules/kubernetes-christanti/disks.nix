{ lib, ... }: {
  config = {
    fileSystems = builtins.listToAttrs (
      map (i: {
        name = "/var/ramona/kubernetes/volumes/discovery/${toString i}";
        value = {
          device = "/var/ramona/kubernetes/volumes/storage/${toString i}";
          options = [ "bind" ];
          fsType = "none";
        };
      }) (lib.range 0 9)
    );

    systemd.tmpfiles.rules =
      (map (i: "d /var/ramona/kubernetes/volumes/storage/${toString i} - - - - -") (lib.range 0 9))
      ++ [ "d /var/ramona/kubernetes/volumes/discovery/ - - - - -" ];
  };
}
