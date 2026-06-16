_: {
  config = {
    systemd.tmpfiles.rules = [
      "d '/var/ceph/mon' - - - - -"
    ];
    boot.kernelModules = [
      "ceph"
      "rbd"
      "nvme_tcp"
    ];
  };
}
