{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./certificates.nix
    ./containerd.nix
    ./control-plane-load-balancer.nix
    ./etcd.nix
    ./kube-apiserver.nix
    ./kube-controller-manager.nix
    ./kube-proxy.nix
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
            internal-apiserver-ip = lib.mkOption { type = str; };
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

            control-plane-port = lib.mkOption {
              type = port;
              default = 6444;
            };
            cluster-name = lib.mkOption {
              type = str;
            };
            certificates = lib.mkOption {
              type = attrsOf (submodule {
                options = {
                  common_name = lib.mkOption { type = str; };
                  parent_ca = lib.mkOption { type = str; };
                  issuer = lib.mkOption {
                    type = str;
                  };
                  hosts = lib.mkOption { type = listOf str; };
                  ips = lib.mkOption { type = listOf str; };
                  owner_user = lib.mkOption {
                    type = str;
                    default = "kubernetes";
                  };
                  owner_group = lib.mkOption {
                    type = str;
                    default = "kubernetes";
                  };
                  pathname_override = lib.mkOption {
                    type = nullOr str;
                    default = null;
                  };
                };
              });
            };
            accounts = lib.mkOption {
              type = attrsOf (submodule {
                options = {
                  config_file = lib.mkOption { type = str; };
                  common_name = lib.mkOption { type = str; };
                  issuer = lib.mkOption {
                    type = str;
                  };
                };
              });
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

    ramona = {
      updates = {
        mode = "boot";
        post-update = "touch /var/run/reboot-required";
      };
      vault-agent = {
        role = "hosts-kubernetes-${config.ramona.kubernetes.cluster-name}";
      };
      host-group-names = [
        "kubernetes/${config.ramona.kubernetes.cluster-name}"
      ]
      ++ (
        if config.ramona.kubernetes.is-control-plane then
          [ "kubernetes/${config.ramona.kubernetes.cluster-name}/control-plane" ]
        else
          [ ]
      );
      kubernetes.certificates =
        (
          if config.ramona.kubernetes.is-control-plane then
            {
              etcd = {
                common_name = "etcd-${config.networking.hostName}";
                parent_ca = "pki-kubernetes-${config.ramona.kubernetes.cluster-name}-etcd";
                hosts = [ config.networking.hostName ];
                ips = [
                  config.ramona.kubernetes.ip
                  "127.0.0.1"
                ];
                pathname_override = "etcd/server";
                owner_user = "etcd";
                owner_group = "etcd";
                issuer = "clientserver";
              };
              etcd-peer = {
                common_name = "etcd-${config.networking.hostName}";
                parent_ca = "pki-kubernetes-${config.ramona.kubernetes.cluster-name}-etcd";
                hosts = [ config.networking.hostName ];
                ips = [
                  config.ramona.kubernetes.ip
                  "127.0.0.1"
                ];
                pathname_override = "etcd/peer";
                owner_user = "etcd";
                owner_group = "etcd";
                issuer = "clientserver";
              };
              etcd-healtcheck-client = {
                common_name = "kube-etcd-${config.networking.hostName}";
                parent_ca = "pki-kubernetes-${config.ramona.kubernetes.cluster-name}-etcd";
                pathname_override = "etcd/healtcheck-client";
                issuer = "client";
              };
              apiserver-etcd-client = {
                common_name = "kube-apiserver-etcd-client";
                parent_ca = "pki-kubernetes-${config.ramona.kubernetes.cluster-name}-etcd";
                issuer = "client";
              };
              apiserver = {
                common_name = "kube-apiserver";
                parent_ca = "pki-kubernetes-${config.ramona.kubernetes.cluster-name}";
                issuer = "server";
                hosts = [
                  config.networking.hostName
                  "control-plane.${config.ramona.kubernetes.cluster-name}.i.ramona.fun"
                ];
                ips = [
                  config.ramona.kubernetes.ip
                  config.ramona.kubernetes.internal-apiserver-ip
                  "127.0.0.1"
                ];
              };
              front-proxy-client = {
                common_name = "front-proxy-client";
                parent_ca = "pki-kubernetes-${config.ramona.kubernetes.cluster-name}-front-proxy";
                issuer = "client";
              };
              apiserver-kubelet-client = {
                common_name = "kube-apiserver";
                parent_ca = "pki-kubernetes-${config.ramona.kubernetes.cluster-name}";
                issuer = "masters";
              };
            }
          else
            { }
        )
        // {
        };
      kubernetes.accounts = {
        default-admin = {
          config_file = "admin.conf";
          common_name = "kubernetes-admin";
          issuer = "cluster-admins";
        };
        default-super-admin = {
          config_file = "super-admin.conf";
          common_name = "kubernetes-super-admin";
          issuer = "masters";
        };
        default-auth = {
          config_file = "kubelet.conf";
          common_name = "system:node:${config.networking.hostName}";
          issuer = "nodes";
        };
        default-controller-manager = {
          config_file = "controller-manager.conf";
          common_name = "system:kube-controller-manager";
          issuer = "client";
        };
        default-scheduler = {
          config_file = "scheduler.conf";
          common_name = "system:kube-scheduler";
          issuer = "client";
        };
        default-kube-proxy = {
          config_file = "kube-proxy.conf";
          common_name = "system:kube-proxy";
          issuer = "client";
        };
      };
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

    systemd.tmpfiles.rules = [
      "d /etc/kubernetes/  - - - - -"
    ];
  };
}
