let
  ssh-keys = import ../data/ssh-keys.nix;

  users = [ssh-keys.ramona ssh-keys.ramona-blackwood];

  shadowsoul = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCskURPeN0/gJSkJXTMMuU8SXcZ1gOUhVzdF1undjFitwIaiKLz/zS8n/ywvXX55ulCNWyAyRyZAw7wfDj+p3Jd9vAtqhdHmOhXAHW4Gmfh/4PWHWckiPFF0s5tGeEqB+vW33Q0WoiYpu9+/egLYCmAoKbCe1G3i45Z+2w5xneyP65FTBOn51XYMA8PyDeBMtwqESWJVV86v9z3aGkTu562fWW4tnrQrMuH7RspSKZ1dZcN+MiQYvvhQbxtFK6bMtQLCFpPnaoKvoETUI4/F/5GGVVpPnQmWo1mKdDO1tYTNIt0r/2ZXiVmc+QvC6XDnY9V3nkutHePqoSDigwRK8Iz+UEHBKohhPiFGYqEfznVr+f1EKA5hquJsqtWClcJ3sK3+Rwp/2nnJL5zAhNAQjF3S2vCENjKUltfd64dJM0t5Qq4f6wyve5oF8BlUqgLIF8jz4hXh0MpkZgJdSZ5Ouk+pK3v+sgvoEM2Olr1fbgWdmytW881hnFoWFQznOo6FFk=";
  hallewell = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCuqrAiE9QR6zvndMLUHNdEwr5x9EZ1OZKU5QEcT8G9iwK9WE3oLzgXS3eL3uDs0GrKmt1GA8PBj9rpkXsxU3d4vUYBLNM6UTIMsMAPvuBnBiKi3qhngcpSIne5E/ZAzAj1H3WWJ1XBCaP4pX67xe1ncBK7L/sju5o04nJoqqjEtXnE3NJx3SW4ZJurn6gP13HHkdcz/Rk2qxj77vemIU9xSXSqETGZet6rh5B29fOaJG4DejaYHnhTzZmq6wV9f8YzkUhuNl903HdwtqYtnnLxBgUvD6+1A2/Dc9Zf1jdwK1wCsC6XVo7Ez2dnP7lZvM/Wdw1Lf7RETDYsMJLLIwxKB+ZjEaz5YYDA3St2Qa6JyfzUZ309nW2PKAzATJHTi6QVuITsRoR5JDLN+u8KgiUmjyUP4CRsYU9GOohDi99UZuh9Kf7xkHQ3RvhBHaWWvz0zItnZzKw/U+FSxm9gWScuU7HvnZprROh+sCh9vbvG2SAj+YNTLPl5pZGE9deBu5npzwaYv8u5HMI5uaOdp+1JnBLWoSIY2U9at0f4g5vn/Hgxu9C1odH7AkmHNaBlyjRNnQF9ln7TL0A5FpjhCBbP8lcVSlywkuApc7yj9RFr+BEDsBBASXtDXYh7hN2hbHgFFbr5fG5q98V8WJgiille0DX0zHNjdlJfRjK2O/nNsQ==";
  blackwood = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDqwjKOzg1EP89c+MQOjR7tEPIR3I5qp8cptCw1K83qQW9+9ysaWuEcmpGszvot2t+KHXijHXxyBr2FdWWRUZWrZbF3fFWfEpWF3YALpxu0qJBuyFkPA077C2V6guPLCruMPOfBa8sklLqlgGZCDF8rhEUjw9uCRveTdqEpDv9u1A1uR3txh4lecbU4PmvSZ4vlvSlBOwEvGrgMF5Y23c5j6lxy/165vtY3JQsaQDQkEpBLI2mtyuVMxOV1pKOCtZf62gFuC5SpB9IC9uDUgY+KzDUfMxZFEiCS5j/WZjX+SxtG09iOf70OUJtVwfAKFdHgEM54r8gqvIC8506sKZsX72LKzBQMFkFNxXwd+JhUJrYWjUEcj0cd/8YxRPXvaVq4vPZpUAn60ZiBM7A/SJO9DPZoczP6tJG0bh4cuolmoei+KzujRTghSsEoL8WX02AL5il2bJfvRLODdSC+nmB2lQNUu8z+w6Z/he2jE2A9fR5fbuZgY2cw6wScAeVBL43bOqX5Q+7P9v2diceHqRIeEOrE+61vyCPuMp8cy93r8QM+lruoF7qfM/EusIN467BdxJNRqrNPTdd6GSSDMclLkdQ5qL5NHpz8qUqSwqT9ulWlzoyP+lRB/wFUxfdcgb6cDAl/ot6KhWgG9J1hzQfpnzmapAG8wCx+EzwrmjXaUQ== root@kexec";
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
