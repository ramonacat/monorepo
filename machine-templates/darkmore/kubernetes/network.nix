{ config, lib, ... }: {
  config = {
    environment.etc =
      let
        config-path = builtins.replaceStrings [ "/etc" ] [ "" ] config.ramona.kubernetes.cni.config;
      in
      {
        "${config-path}/10-bridge.conf".text = ''
          {
              "cniVersion": "0.2.0",
              "name": "mynet",
              "type": "bridge",
              "bridge": "cni0",
              "isGateway": true,
              "ipMasq": false,
              "hairpinMode": true,
              "ipam": {
                  "type": "host-local",
                  "subnet": "${config.ramona.kubernetes.host-pod-cidr}",
                  "routes": [
                      { "dst": "0.0.0.0/0", "gw": "${config.ramona.kubernetes.ip}" }
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
    networking = {
      nftables.tables.masq-cni = {
        content = ''
          chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;

              ip saddr ${config.ramona.kubernetes.host-pod-cidr} ip daddr ${config.ramona.kubernetes.host-pod-cidr} counter accept
              ip saddr ${config.ramona.kubernetes.host-pod-cidr} ip daddr 10.0.0.0/8 counter accept

              ip saddr ${config.ramona.kubernetes.host-pod-cidr} ip daddr != 224.0.0.0/4 counter masquerade
          };
        '';
        family = "ip";
      };

      firewall.trustedInterfaces = [
        "enp7s0"
        "cni0"
      ];

      firewall.interfaces.tailscale0.allowedTCPPorts =
        lib.mkIf config.ramona.kubernetes.is-control-plane
          [
            6443 # kubernetes api server (for admin access)
          ];
    };

    ramona.wireguard = {
      enabled = true;
    };

    ramona.router = {
      enabled = true;

      # do not accept local routes
      filter_import = ''
        if net ~ [ 10.0.0.0/11+ ] || net = [ 10.0.0.0/11 ] then {
            reject "not importing local network";
        }

        if net ~ [ 10.0.0.0/8+ ] then {
            accept;
        }

        reject "prefix outside of our local network";
      '';
      interfaces = [
        {
          name_pattern = "enp7s*";
          cost = 500;
          kind = "Passive";
        }
      ];
      additional_config = ''
        protocol static {
            ipv4 { export all; };
            route 10.0.0.0/11 via 10.0.0.1%enp7s0 onlink;
        }
      '';
    };
  };
}
