let
  ssh-keys = import ../data/ssh-keys.nix;

  users = [ssh-keys.ramona.default];

  shadowsoul = ssh-keys.machines.shadowsoul-rsa;
  hallewell = ssh-keys.machines.hallewell-rsa;
  crimson = ssh-keys.machines.crimson-rsa;
  thornton = ssh-keys.machines.thornton-rsa;
  allMachines = [hallewell shadowsoul crimson thornton];
in {
  "shadowsoul-ssh-host-key-rsa.age".publicKeys = users ++ [shadowsoul];
  "shadowsoul-ssh-host-key-ed25519.age".publicKeys = users ++ [shadowsoul];
  "crimson-ssh-host-key-rsa.age".publicKeys = users ++ [crimson];
  "crimson-ssh-host-key-ed25519.age".publicKeys = users ++ [crimson];
  "hallewell-ssh-host-key-rsa.age".publicKeys = users ++ [hallewell];
  "hallewell-ssh-host-key-ed25519.age".publicKeys = users ++ [hallewell];
  "thornton-ssh-host-key-rsa.age".publicKeys = users ++ [thornton];
  "thornton-ssh-host-key-ed25519.age".publicKeys = users ++ [thornton];
  "tailscale-auth-key.age".publicKeys = users ++ allMachines;
  "github-pat-runner-registration.age".publicKeys = users ++ [hallewell];
  "minio-root.age".publicKeys = users ++ [hallewell];
  "minio-tempo.age".publicKeys = users ++ [hallewell];
  "minio-terraform-state.age".publicKeys = users;
  "photoprism-password.age".publicKeys = users ++ [hallewell];
  "backups-env.age".publicKeys = users ++ allMachines;
  "backups-rclone.age".publicKeys = users ++ allMachines;
  "rad-environment.age".publicKeys = users ++ allMachines;
  "rad-ras-token.age".publicKeys = users ++ allMachines;
  "ramona-password.age".publicKeys = users ++ allMachines;
  "ras2-db-config.age".publicKeys = users ++ [hallewell];
  "ras2-telegraf-db-config.age".publicKeys = users ++ [hallewell];
  "restic-repository-password.age".publicKeys = users ++ allMachines;
  "root-password.age".publicKeys = users ++ allMachines;
  "telegraf-database.age".publicKeys = users ++ allMachines;
  "terraform-tokens.age".publicKeys = users;
  "transmission-credentials.age".publicKeys = users ++ [shadowsoul];
  "universal-root.age".publicKeys = users ++ allMachines;
}
