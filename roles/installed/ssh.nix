{ config, ... }: {
  config =
    let
      ssh-keys = import ../../data/ssh-keys.nix;
    in
    {
      services.openssh = {
        openFirewall = false;
      };
      networking.firewall.extraInputRules = ''
        ip saddr 10.0.0.0/8 tcp dport 22 accept
        ip saddr 100.64.0.0/10 tcp dport 22 accept
      '';

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

        cat ${
          config.age.secrets."${config.networking.hostName}-ssh-host-key-rsa".path
        } > /etc/ssh/ssh_host_rsa_key
        cat ${
          config.age.secrets."${config.networking.hostName}-ssh-host-key-ed25519".path
        } > /etc/ssh/ssh_host_ed25519_key
      '';
    };
}
