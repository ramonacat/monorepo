{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = {
    virtualisation.containerd = {
      enable = true;
      settings = {
        plugins."io.containerd.grpc.v1.cri" = {
          cni.bin_dir = "/opt/cni/bin/";
        };
      };
    };

    environment.systemPackages = [
      pkgs.kubernetes
      pkgs.kubectl
    ];

    # using services.kubernetes will create a configuration that assumes using those for everything, which is not compatible with kubeadm
    systemd =
      let
        kubelet-config = "/var/lib/kubelet/config.yaml";
        kubelet-kubeconfig = "/etc/kubernetes/kubelet.conf";
      in
      {
        services.kubelet = {
          description = "kubernetes kubelet service";
          wantedBy = [ "default.target" ];
          after = [
            "containerd.service"
            "network.target"
          ];
          # these are various binaries needed by the kubelet when it runs, the list is stolen from: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/cluster/kubernetes/kubelet.nix#L332
          # be careful removing things, as they are not needed for startup, but cause things to fail later if missing
          path = with pkgs; [
            gitMinimal
            openssh
            util-linuxMinimal
            iproute2
            ethtool
            thin-provisioning-tools
            iptables
            socat
          ];
          serviceConfig = {
            MemoryAccounting = true;
            Restart = "on-failure";
            RestartSec = "1000ms";
            ExecStart =
              let
                kubelet-script = pkgs.writeShellScriptBin "kubelet-wrapper" ''
                  declare -a arguments=()
                  if [[ -f "${kubelet-config}" ]]; then
                    arguments+=("--config=${kubelet-config}")
                  fi

                  kubeconfig=""
                  if [[ -f "${kubelet-kubeconfig}" ]]; then
                    arguments+=("--kubeconfig=${kubelet-kubeconfig}")
                  fi

                  exec ${pkgs.kubernetes}/bin/kubelet "''${arguments[@]}" \
                      --hostname-override=${config.networking.hostName} \
                      --fail-swap-on=false \
                      --node-ip=10.70.0.${toString (10 + config.ramona.darkmore-control-plane.id)}
                      --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf
                '';
              in
              "${kubelet-script}/bin/kubelet-wrapper";
          };
        };
      };

    services.nginx =
      let
        control-plane-port = 6444;
        control-plane-hostnames = map (i: "10.70.0.${toString (i + 10)}") (
          lib.range 0 (config.ramona.darkmore-control-plane.total-count - 1)
        );
        control-plane-endpoints = map (hostname: "${hostname}:6443") control-plane-hostnames;
      in
      {
        enable = true;
        streamConfig = ''
          upstream k8s_control_plane {
              ${lib.strings.join "" (map (endpoint: "server ${endpoint};") control-plane-endpoints)};
          }

          server {
              listen ${toString control-plane-port};
              proxy_pass k8s_control_plane;
          }
        '';
      };

    boot.kernelModules = [
      # needed by flannel
      "br_netfilter"
      "overlay"
    ];

    networking.firewall.interfaces.enp7s0 = {
      allowedTCPPorts = [
        443 # coredns
        6443 # kube-apiserver
        6444 # loadbalanced kube-apiserver, for administration access
        2379 # etcd
        2380 # etcd
        10250 # kubelet
        10256 # kube-proxy
        10257 # kube-controller-manager
        10259 # kube-scheduler

        4240 # cilium - health checks
        4250 # cilium - mutual authentication port
      ];
      allowedUDPPorts = [
        8472 # cilium - VXLAN
      ];
      allowedTCPPortRanges = [
        {
          from = 30000;
          to = 32767;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 30000;
          to = 32767;
        }
      ];
    };
  };
}
