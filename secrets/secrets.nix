let
  ssh-keys = import ../data/ssh-keys.nix;

  users = [ssh-keys.ramona.default];

  shadowsoul = ssh-keys.machines.shadowsoul-rsa;
  hallewell = ssh-keys.machines.hallewell-rsa;
  crimson = ssh-keys.machines.crimson-rsa;
  thornton = ssh-keys.machines.thornton-rsa;
  allMachines = [hallewell shadowsoul crimson thornton];
in {
  "backups-common-env.age".publicKeys = users ++ allMachines;
  "backups-common-password.age".publicKeys = users ++ allMachines;
  "backups-common-rclone.age".publicKeys = users ++ allMachines;
  "backups-public-env.age".publicKeys = users ++ allMachines;
  "backups-public-password.age".publicKeys = users ++ allMachines;
  "backups-public-rclone.age".publicKeys = users ++ allMachines;
  "crimson-ssh-host-key-ed25519.age".publicKeys = users ++ [crimson];
  "crimson-ssh-host-key-rsa.age".publicKeys = users ++ [crimson];
  "github-pat-runner-registration.age".publicKeys = users ++ [hallewell];
  "hallewell-ssh-host-key-ed25519.age".publicKeys = users ++ [hallewell];
  "hallewell-ssh-host-key-rsa.age".publicKeys = users ++ [hallewell];
  "minio-root.age".publicKeys = users ++ [hallewell];
  "minio-tempo.age".publicKeys = users ++ [hallewell];
  "minio-terraform-state.age".publicKeys = users;
  "nix-serve-key.age".publicKeys = users ++ [hallewell];
  "photoprism-password.age".publicKeys = users ++ [hallewell];
  "rad-environment.age".publicKeys = users ++ allMachines;
  "rad-ras-token.age".publicKeys = users ++ allMachines;
  "ramona-password.age".publicKeys = users ++ allMachines;
  "ras2-db-config.age".publicKeys = users ++ [hallewell];
  "ras2-telegraf-db-config.age".publicKeys = users ++ [hallewell];
  "root-password.age".publicKeys = users ++ allMachines;
  "shadowsoul-ssh-host-key-ed25519.age".publicKeys = users ++ [shadowsoul];
  "shadowsoul-ssh-host-key-rsa.age".publicKeys = users ++ [shadowsoul];
  "tailscale-auth-key.age".publicKeys = users ++ allMachines;
  "telegraf-database.age".publicKeys = users ++ allMachines;
  "terraform-tokens.age".publicKeys = users;
  "thornton-ssh-host-key-ed25519.age".publicKeys = users ++ [thornton];
  "thornton-ssh-host-key-rsa.age".publicKeys = users ++ [thornton];
  "transmission-credentials.age".publicKeys = users ++ [shadowsoul];
}
