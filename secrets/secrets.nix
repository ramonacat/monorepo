let
  ssh-keys = import ../data/ssh-keys.nix;

  users = [ ssh-keys.ramona.default ];
  ci = [ ssh-keys.root.ci ];

  shadowsoul = ssh-keys.machines.shadowsoul.rsa;
  hallewell = ssh-keys.machines.hallewell.rsa;

  darkmore-control-plane-0 = ssh-keys.machines.darkmore-control-plane-0.rsa;
  darkmore-control-plane-1 = ssh-keys.machines.darkmore-control-plane-1.rsa;
  darkmore-control-plane-2 = ssh-keys.machines.darkmore-control-plane-2.rsa;
  darkmore-worker-0 = ssh-keys.machines.darkmore-worker-0.rsa;

  workstations = [ ];

  privateMachines = [
    hallewell
    shadowsoul
  ];

  publicServers = [
    darkmore-control-plane-0
    darkmore-control-plane-1
    darkmore-control-plane-2

    darkmore-worker-0
  ];

  allMachines = privateMachines ++ publicServers;
in
{
  "darkmore-control-plane-0-ssh-host-key-ed25519.age".publicKeys =
    users
    ++ ci
    ++ [
      darkmore-control-plane-0
    ];
  "darkmore-control-plane-0-ssh-host-key-rsa.age".publicKeys =
    users ++ ci ++ [ darkmore-control-plane-0 ];
  "darkmore-control-plane-1-ssh-host-key-ed25519.age".publicKeys =
    users
    ++ ci
    ++ [
      darkmore-control-plane-1
    ];
  "darkmore-control-plane-1-ssh-host-key-rsa.age".publicKeys =
    users ++ ci ++ [ darkmore-control-plane-1 ];
  "darkmore-control-plane-2-ssh-host-key-ed25519.age".publicKeys =
    users
    ++ ci
    ++ [
      darkmore-control-plane-2
    ];
  "darkmore-control-plane-2-ssh-host-key-rsa.age".publicKeys =
    users ++ ci ++ [ darkmore-control-plane-2 ];
  "darkmore-worker-0-ssh-host-key-ed25519.age".publicKeys =
    users
    ++ ci
    ++ [
      darkmore-worker-0
    ];
  "darkmore-worker-0-ssh-host-key-rsa.age".publicKeys = users ++ ci ++ [ darkmore-worker-0 ];
  "darkmore-kubeconfig.age".publicKeys = users ++ ci;
  "backups-common-env.age".publicKeys = users ++ privateMachines;
  "backups-common-password.age".publicKeys = users ++ privateMachines;
  "backups-common-rclone.age".publicKeys = users ++ privateMachines;
  "backups-public-env.age".publicKeys = users ++ publicServers;
  "backups-public-password.age".publicKeys = users ++ publicServers;
  "backups-public-rclone.age".publicKeys = users ++ publicServers;
  "github-pat-runner-registration.age".publicKeys = users ++ [ hallewell ];
  "hallewell-ssh-host-key-ed25519.age".publicKeys = users ++ ci ++ [ hallewell ];
  "hallewell-ssh-host-key-rsa.age".publicKeys = users ++ ci ++ [ hallewell ];
  "hallewell-syncthing-cert.age".publicKeys = users ++ [ hallewell ];
  "hallewell-syncthing-key.age".publicKeys = users ++ [ hallewell ];
  "nix-serve-key.age".publicKeys = users ++ [ hallewell ];
  "nix-serve-ssh-key.age".publicKeys = users ++ allMachines;
  "photoprism-password.age".publicKeys = users ++ [ hallewell ];
  "rad-environment.age".publicKeys = users ++ allMachines;
  "rad-ras-token.age".publicKeys = users ++ allMachines;
  "radarr-api-key.age".publicKeys = users ++ [ hallewell ];
  "shadowsoul-ssh-host-key-ed25519.age".publicKeys = users ++ ci ++ [ shadowsoul ];
  "shadowsoul-ssh-host-key-rsa.age".publicKeys = users ++ ci ++ [ shadowsoul ];
  "shadowsoul-syncthing-cert.age".publicKeys = users ++ [ shadowsoul ];
  "shadowsoul-syncthing-key.age".publicKeys = users ++ [ shadowsoul ];
  "sonarr-api-key.age".publicKeys = users ++ [ hallewell ];
  "terraform-tokens.age".publicKeys = users ++ ci;
  "transmission-credentials.age".publicKeys = users ++ ci ++ [ shadowsoul ];
  "user-password-private-ramona.age".publicKeys = users ++ privateMachines;
  "user-password-private-root.age".publicKeys = users ++ privateMachines;
  "user-password-public-ramona.age".publicKeys = users ++ publicServers;
  "user-password-public-root.age".publicKeys = users ++ publicServers;
  "wireless-passwords.age".publicKeys = users ++ workstations;
  "github-pat-npm-registry.age".publicKeys = users;
}
