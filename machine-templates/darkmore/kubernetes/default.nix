{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./containerd.nix
    ./control-plane-load-balancer.nix
    ./etcd.nix
    ./kube-apiserver.nix
    ./kube-controller-manager.nix
    ./kube-scheduler.nix
    ./kubelet.nix
    ./longhorn-storage.nix
    ./network.nix
  ];
  options = {
    ramona.kubernetes = lib.mkOption {
      type =
        with lib.types;
        submodule {
          options = {
            ip = lib.mkOption { type = str; };
            hostname = lib.mkOption { type = str; };
            is-control-plane = lib.mkOption { type = bool; };
            cluster-dns-ip = lib.mkOption { type = str; };

            all-nodes = lib.mkOption {
              type = listOf (submodule {
                options = {
                  ip = lib.mkOption { type = str; };
                  hostname = lib.mkOption { type = str; };
                  is-control-plane = lib.mkOption { type = bool; };
                };
              });
            };
            pod-cidr = lib.mkOption {
              type = str;
            };
            host-pod-cidr = lib.mkOption {
              type = str;
            };
            service-cidr = lib.mkOption {
              type = str;
            };

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
    networking.hostName = config.ramona.kubernetes.hostname;

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

    ramona.updates = {
      mode = "boot";
      post-update = "touch /var/run/reboot-required";
    };

    systemd.targets.kubernetes = {
      description = "kubernetes";
      wantedBy = [ "multi-user.target" ];
    };

    users.users.kubernetes = {
      isSystemUser = true;
      group = "kubernetes";
    };
    users.groups.kubernetes = { };
  };
}
