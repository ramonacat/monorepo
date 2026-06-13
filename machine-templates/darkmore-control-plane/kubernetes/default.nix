{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./containerd.nix
    ./control-plane-load-balancer.nix
    ./kubelet.nix
  ];
  options = {
    ramona.kubernetes = lib.mkOption {
      type =
        with lib.types;
        submodule {
          options = {
            cni = lib.mkOption {
              type = submodule {
                options = {
                  bin = lib.mkOption {
                    type = path;
                    default = "/opt/cni/bin/";
                  };
                  config = lib.mkOption {
                    type = path;
                    default = "/etc/cni/net.d/";
                  };
                };
              };
            };
            control-plane-port = lib.mkOption {
              type = port;
              default = 6444;
            };
          };
        };
    };
  };
  config = {
    environment.systemPackages = [
      pkgs.kubernetes
      pkgs.kubectl
      pkgs.kubernetes-helm
    ];

    boot.kernelModules = [
      # needed by flannel
      "br_netfilter"
      "overlay"
    ];

    networking.firewall.trustedInterfaces = [
      "enp7s0"
      "cni0"
      "flannel.0"
      "flannel.1"
    ];

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      6443 # kubernetes api server (for admin access)
    ];

    ramona.updates = {
      mode = "boot";
      post-update = "touch /var/run/reboot-required";
    };
  };
}
