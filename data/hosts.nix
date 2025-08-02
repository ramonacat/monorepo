{
  flake,
  lib,
}: rec {
  nixos = builtins.filter (k: k != "iso") (lib.mapAttrsToList (k: _: k) flake.nixosConfigurations);
  windows = [
    "angelsin"
    "evillian"
    "moonfall"
  ];
  all = nixos ++ windows;
  # these no longer exist
  # "ananas"
  # "blackwood"
  # "caligari"
  # "redwood"
  # "shadowmend"
}
