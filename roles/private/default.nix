_: {
  imports = [
    ./restic-secrets.nix
    ./syncthing.nix
  ];
  config = {
    ramona.machine.roles = ["private"];
  };
}
