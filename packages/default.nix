inputs: {
  apps = {
    ramona-fun = import ./ramona-fun.nix inputs;
    sawin-gallery = import ./sawin-gallery.nix inputs;
    fup = import ./fup.nix inputs;
  };
}
