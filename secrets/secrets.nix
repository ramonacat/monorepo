let
  ssh-keys = import ../data/ssh-keys.nix;

  users = [ssh-keys.ramona ssh-keys.ramona-blackwood];

  shadowsoul = ssh-keys.machine-shadowsoul;
  hallewell = ssh-keys.machine-hallewell;
  blackwood = ssh-keys.machine-blackwood;
  allMachines = [hallewell shadowsoul blackwood];
in {
  "github-pat-runner-registration.age".publicKeys = users ++ [blackwood hallewell];
  "minio-root.age".publicKeys = users ++ [hallewell];
  "minio-tempo.age".publicKeys = users ++ [hallewell];
  "minio-terraform-state.age".publicKeys = users;
  "photoprism-password.age".publicKeys = users ++ [hallewell];
  "postgres-backups-env.age".publicKeys = users ++ allMachines;
  "postgres-backups-rclone.age".publicKeys = users ++ allMachines;
  "rad-environment.age".publicKeys = users ++ allMachines;
  "rad-ras-token.age".publicKeys = users ++ allMachines;
  "ramona-password.age".publicKeys = users ++ allMachines;
  "ras-environment.age".publicKeys = users ++ [hallewell];
  "ras2-db-config.age".publicKeys = users ++ [hallewell];
  "ras2-telegraf-db-config.age".publicKeys = users ++ [hallewell];
  "restic-repository-password.age".publicKeys = users ++ allMachines;
  "root-password.age".publicKeys = users ++ allMachines;
  "telegraf-database.age".publicKeys = users ++ allMachines;
  "terraform-tokens.age".publicKeys = users;
  "transmission-credentials.age".publicKeys = users ++ [shadowsoul];
  "universal-root.age".publicKeys = users ++ allMachines;
  "hostkey-rsa-initrd.age".publicKeys = users ++ allMachines;
  "hostkey-ed25519-initrd.age".publicKeys = users ++ allMachines;
}
