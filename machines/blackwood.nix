{nixpkgs}: _: {
  imports = [
    (import ./_all.nix {inherit nixpkgs;})

    ./_notlive.nix
    ./blackwood/backup-target.nix
    ./blackwood/hardware.nix
    ./blackwood/networking.nix
    ../users/ramona/installed.nix
    ../users/root/installed.nix
  ];
}
