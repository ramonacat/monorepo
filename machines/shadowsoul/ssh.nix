{config, ...}: {
  config = let
    ssh-keys = import ../../data/ssh-keys.nix;
  in {
    age.secrets = {
      shadowsoul-ssh-host-key-ed25519 = {
        file = ../../secrets/shadowsoul-ssh-host-key-ed25519.age;
      };
      shadowsoul-ssh-host-key-rsa = {
        file = ../../secrets/shadowsoul-ssh-host-key-rsa.age;
      };
    };

    systemd.services.sshd.preStart = ''
      echo << EOF > /etc/ssh/ssh_host_rsa_key.pub
      ${ssh-keys.machines.shadowsoul-rsa}
      EOF

      echo << EOF > /etc/ssh/ssh_host_ed25519_key.pub
      ${ssh-keys.machines.shadowsoul-ed25519}
      EOF

      cat ${config.age.secrets.shadowsoul-ssh-host-key-rsa.path} > /etc/ssh/ssh_host_rsa_key
      cat ${config.age.secrets.shadowsoul-ssh-host-key-ed25519.path} > /etc/ssh/ssh_host_ed25519_key
    '';
  };
}
