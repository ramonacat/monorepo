_: {
  config = {
    systemd.tmpfiles.rules = [
      "d '/var/ceph/mon' - - - - -"
    ];
  };
}
