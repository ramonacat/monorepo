{ config, lib, ... }: {
  config = {
    services.nginx =
      let
        control-plane-endpoints = map (
          host: "${host.ip}:6443"
        ) config.ramona.darkmore-control-plane.all-nodes;
      in
      {
        enable = true;
        streamConfig = ''
          upstream k8s_control_plane {
              ${lib.strings.join "" (map (endpoint: "server ${endpoint};") control-plane-endpoints)};
          }

          server {
              listen ${toString config.ramona.kubernetes.control-plane-port};
              proxy_pass k8s_control_plane;
          }
        '';
      };

  };
}
