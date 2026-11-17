_: {
  config = {
    virtualisation.containerd = {
      enable = true;
      settings = {
        plugins."io.containerd.grpc.v1.cri" = {
          cni = {
            bin_dir = "/opt/cni/bin";
            conf_dir = "/etc/cni/net.d/";
          };
          containerd.runtimes.runc = {
            runtime_type = "io.containerd.runc.v2";
            options.SystemdCgroup = true;
          };
        };
      };
    };
  };
}
