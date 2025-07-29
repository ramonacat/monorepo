rec {
  # TODO this should be automated and taken from the flake, we just need a way to differentiate between the ISO and actual machines
  nixos = [
    "hallewell"
    "shadowsoul"
    "crimson"
  ];
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
