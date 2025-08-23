{config, ...}: {
  config = let
    ssh-keys = import ../../data/ssh-keys.nix;
  in {
    services.openssh = {
      openFirewall = false;
    };
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = config.services.openssh.ports;

    age.secrets = {
      "${config.networking.hostName}-ssh-host-key-ed25519" = {
        file = ../../secrets + "/${config.networking.hostName}-ssh-host-key-ed25519.age";
      };
      "${config.networking.hostName}-ssh-host-key-rsa" = {
        file = ../../secrets + "/${config.networking.hostName}-ssh-host-key-rsa.age";
      };
    };

    systemd.services.sshd.preStart = ''
      echo << EOF > /etc/ssh/ssh_host_rsa_key.pub
      ${ssh-keys.machines."${config.networking.hostName}".rsa}
      EOF

      echo << EOF > /etc/ssh/ssh_host_ed25519_key.pub
      ${ssh-keys.machines."${config.networking.hostName}".ed25519}
      EOF

      cat ${config.age.secrets."${config.networking.hostName}-ssh-host-key-rsa".path} > /etc/ssh/ssh_host_rsa_key
      cat ${config.age.secrets."${config.networking.hostName}-ssh-host-key-ed25519".path} > /etc/ssh/ssh_host_ed25519_key
    '';
  };
}
