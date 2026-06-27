{ config, lib, ... }: {
  config = {
    services.nginx =
      let
        control-plane-endpoints = map (host: "${host.ip}:6443") (
          builtins.filter (x: x.is-control-plane) config.ramona.kubernetes.all-nodes
        );
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
