_: {
  imports = [
    ./restic-secrets.nix
    ./syncthing.nix
  ];
  config = {
    ramona.roles = ["private"];
  };
}
