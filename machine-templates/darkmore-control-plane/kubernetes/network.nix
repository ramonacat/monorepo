{ config, ... }: {
  config = {
    environment.etc = {
      "${config.ramona.kubernetes.cni.config}/10-bridge.conf".text = ''
        {
            "cniVersion": "0.2.0",
            "name": "mynet",
            "type": "bridge",
            "bridge": "cni0",
            "isGateway": true,
            "ipMasq": true,
            "ipam": {
                "type": "host-local",
                "subnet": "${config.ramona.kubernetes.podCidr}",
                "routes": [
                    { "dst": "0.0.0.0/0" }
                ]
            }
        }
      '';
      "${config.ramona.kubernetes.cni.config}/99-loopback.conf".text = ''
        {
            "cniVersion": "0.2.0",
            "name": "lo",
            "type": "loopback"
        }
      '';
    };

    networking.firewall.trustedInterfaces = [
      "enp7s0"
      "cni0"
    ];

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      6443 # kubernetes api server (for admin access)
    ];
  };
}
