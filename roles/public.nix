_: {
  imports =
    [
      ../modules/machine-kind.nix
    ]
    ++ (import ../libs/nix/nix-files-from-dir.nix ./public);
  config = {
    ramona.machine = {
      type = "server";
      visibility = "public";
    };
  };
}
