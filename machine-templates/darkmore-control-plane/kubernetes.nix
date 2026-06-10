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
    services.kubernetes = {
      apiserverAddress = "https://localhost:6444";
      clusterCidr = "10.71.0.0/16";

      kubelet = {
        enable = true;
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
  };
}
