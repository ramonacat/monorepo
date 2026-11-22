{ config, lib, ... }: {
  config = {
    environment.etc =
      let
        config-path = "/cni/net.d";
      in
      {
        "${config-path}/10-bridge.conf".text = ''
          {
              "cniVersion": "0.2.0",
              "name": "mynet",
              "type": "bridge",
              "bridge": "cni0",
              "isGateway": true,
              "ipMasq": true,
              "hairpinMode": true,
              "ipam": {
                  "type": "host-local",
                  "subnet": "${config.ramona.kubernetes.host-pod-cidr}",
                  "routes": [
                      { "dst": "0.0.0.0/0" }
                  ]
              }
          }
        '';
        "${config-path}/20-portmap.conf".text = ''
          {
              "cniVersion": "0.2.0",
              "name": "partmap",
              "type": "portmap",
              "capabilities": {"portMappings": true}
          }
        '';
        "${config-path}/99-loopback.conf".text = ''
          {
              "cniVersion": "0.2.0",
              "name": "lo",
              "type": "loopback"
          }
        '';
      };

    networking.firewall.trustedInterfaces = [
      "cni0"
    ];

    networking.firewall.interfaces.tailscale0.allowedTCPPorts =
      lib.mkIf config.ramona.kubernetes.is-control-plane
        [
          6443 # kubernetes api server (for admin access)
        ];

    ramona.router = {
      enabled = true;

      # do not accept local routes
      filter_import = ''
        if net ~ [ 10.0.0.0/8+ ] then {
            accept;
        }

        reject "prefix outside of our local network";
      '';
    };
  };
}
