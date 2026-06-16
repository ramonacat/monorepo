_: {
  config = {
    systemd.tmpfiles.rules = [
      "d '/var/ceph/mon' - - - - -"
    ];
    boot.kernelModules = [
      "rbd"
      "nvme_tcp"
    ];
  };
}
