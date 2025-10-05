let
  ssh-keys = import ../data/ssh-keys.nix;

  users = [ssh-keys.ramona.default];

  angelsin-linux = ssh-keys.machines.angelsin-linux.rsa;
  shadowsoul = ssh-keys.machines.shadowsoul.rsa;
  hallewell = ssh-keys.machines.hallewell.rsa;
  crimson = ssh-keys.machines.crimson.rsa;
  thornton = ssh-keys.machines.thornton.rsa;

  workstations = [angelsin-linux];

  privateMachines = [hallewell shadowsoul angelsin-linux];
  publicServers = [crimson thornton];

  allMachines = privateMachines ++ publicServers;
in {
  "angelsin-linux-ssh-host-key-ed25519.age".publicKeys = users ++ [angelsin-linux];
  "angelsin-linux-ssh-host-key-rsa.age".publicKeys = users ++ [angelsin-linux];
  "angelsin-linux-syncthing-cert.age".publicKeys = users ++ [angelsin-linux];
  "angelsin-linux-syncthing-key.age".publicKeys = users ++ [angelsin-linux];
  "backups-common-env.age".publicKeys = users ++ privateMachines;
  "backups-common-password.age".publicKeys = users ++ privateMachines;
  "backups-common-rclone.age".publicKeys = users ++ privateMachines;
  "backups-public-env.age".publicKeys = users ++ publicServers;
  "backups-public-password.age".publicKeys = users ++ publicServers;
  "backups-public-rclone.age".publicKeys = users ++ publicServers;
  "crimson-ssh-host-key-ed25519.age".publicKeys = users ++ [crimson];
  "crimson-ssh-host-key-rsa.age".publicKeys = users ++ [crimson];
  "github-pat-runner-registration.age".publicKeys = users ++ [hallewell shadowsoul];
  "hallewell-ssh-host-key-ed25519.age".publicKeys = users ++ [hallewell];
  "hallewell-ssh-host-key-rsa.age".publicKeys = users ++ [hallewell];
  "hallewell-syncthing-cert.age".publicKeys = users ++ [hallewell];
  "hallewell-syncthing-key.age".publicKeys = users ++ [hallewell];
  "minio-root.age".publicKeys = users ++ [hallewell thornton];
  "minio-tempo.age".publicKeys = users ++ [hallewell];
  "minio-terraform-state.age".publicKeys = users;
  "nix-serve-key.age".publicKeys = users ++ [hallewell];
  "photoprism-password.age".publicKeys = users ++ [hallewell];
  "rad-environment.age".publicKeys = users ++ allMachines;
  "rad-ras-token.age".publicKeys = users ++ allMachines;
  "ras2-db-config.age".publicKeys = users ++ [hallewell];
  "ras2-telegraf-db-config.age".publicKeys = users ++ [hallewell];
  "shadowsoul-ssh-host-key-ed25519.age".publicKeys = users ++ [shadowsoul];
  "shadowsoul-ssh-host-key-rsa.age".publicKeys = users ++ [shadowsoul];
  "shadowsoul-syncthing-cert.age".publicKeys = users ++ [shadowsoul];
  "shadowsoul-syncthing-key.age".publicKeys = users ++ [shadowsoul];
  "tailscale-auth-key.age".publicKeys = users ++ allMachines;
  "telegraf-database.age".publicKeys = users ++ [hallewell thornton];
  "terraform-tokens.age".publicKeys = users;
  "thornton-ssh-host-key-ed25519.age".publicKeys = users ++ [thornton];
  "thornton-ssh-host-key-rsa.age".publicKeys = users ++ [thornton];
  "transmission-credentials.age".publicKeys = users ++ [shadowsoul];
  "user-password-private-ramona.age".publicKeys = users ++ privateMachines;
  "user-password-private-root.age".publicKeys = users ++ privateMachines;
  "user-password-public-ramona.age".publicKeys = users ++ publicServers;
  "user-password-public-root.age".publicKeys = users ++ publicServers;
  "wireless-passwords.age".publicKeys = users ++ workstations;
  "nix-serve-ssh-key.age".publicKeys = users ++ allMachines;
}
