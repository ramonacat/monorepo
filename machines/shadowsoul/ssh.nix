{config, ...}: {
  config = {
    age.secrets = {
      shadowsoul-ssh-host-key-ed25519 = {
        file = ../../secrets/shadowsoul-ssh-host-key-ed25519.age;
      };
      shadowsoul-ssh-host-key-rsa = {
        file = ../../secrets/shadowsoul-ssh-host-key-rsa.age;
      };
    };

    environment.etc = let
      ssh-keys = import ../../data/ssh-keys.nix;
    in {
      "/etc/ssh/ssh_host_rsa_key.pub" = {
        text = ssh-keys.machines.shadowsoul-rsa;
      };
      "/etc/ssh/ssh_host_ed25519_key.pub" = {
        text = ssh-keys.machines.shadowsoul-ed25519;
      };
      "/etc/ssh/ssh_host_rsa_key" = {
        source = config.age.secrets.shadowsoul-ssh-host-key-rsa.path;
      };
      "/etc/ssh/ssh_host_ed25519_key" = {
        source = config.age.secrets.shadowsoul-ssh-host-key-ed25519.path;
      };
    };
  };
}
