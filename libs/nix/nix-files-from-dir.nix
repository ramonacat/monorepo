directory: builtins.map (x: directory + "/${x}") (builtins.filter (f: (builtins.match ".*\\.nix" f) != null) (builtins.attrNames (builtins.readDir directory)))
