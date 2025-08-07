directory: let
  all-items = builtins.attrNames (builtins.readDir directory);
  nix-files = builtins.filter (f: (builtins.match ".*\\.nix" f) != null) all-items;
  except-default-nix = builtins.filter (f: f != "default.nix") nix-files;
in
  builtins.map (x: directory + "/${x}") except-default-nix
