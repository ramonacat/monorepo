{ config, ... }: {
  config = {
    virtualisation.containerd = {
      enable = true;
      settings = {
        plugins."io.containerd.grpc.v1.cri" = {
          cni = {
            bin_dir = config.ramona.kubernetes.cni.bin;
            conf_dir = config.ramona.kubernetes.cni.config;
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
