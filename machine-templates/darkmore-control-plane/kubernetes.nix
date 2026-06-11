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
    };
    environment.systemPackages = [
      pkgs.kubernetes
      pkgs.kubectl
    ];

    # using services.kubernetes will create a configuration that assumes using those for everything, which is not compatible with kubeadm
    # default settings are fine, and what kubeadm expects
    systemd.services.kubelet = {
      description = "kubernetes kubelet service";
      wantedBy = [ "default.target" ];
      after = [
        "containerd.service"
        "network.target"
      ];
      serviceConfig = {
        MemoryAccounting = true;
        Restart = "on-failure";
        RestartSec = "1000ms";
        ExecStart = ''
          ${pkgs.kubernetes}/bin/kubelet \
              --hostname-override=${config.networking.hostName} \
              --fail-swap-on=false
        '';
      };
    };

    services.nginx =
      let
        control-plane-port = 6444;
        control-plane-hostnames = map (
          i:
          let
            set-name = "darkmore-control-plane";
            hostname = "${set-name}-${toString i}";
          in
          "${hostname}.ibis-draconis.ts.net"
        ) (lib.range 0 (config.ramona.darkmore-control-plane.total-count - 1));
        control-plane-endpoints = map (hostname: "${hostname}:6443") control-plane-hostnames;
      in
      {
        streamConfig = ''
          upstream k8s_control_plane {
              ${lib.strings.join "" (map (endpoint: "server ${endpoint};") control-plane-endpoints)};
          }

          server {
              listen ${toString control-plane-port};
          }
        '';
      };

    networking.firewall.interfaces.tailscale0 = {
      allowedTCPPorts = [
        6443 # kube-apiserver
        2379 # etcd
        2380 # etcd
        10250 # kubelet
        10256 # kube-proxy
      ];
      allowedTCPPortRanges = [
        {
          from = 30000;
          to = 32767;
        }
      ];
    };
  };
}
