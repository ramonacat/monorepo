inputs: {
  apps = {
    rad = import ./rad.nix inputs;
    ramona-fun = import ./ramona-fun.nix inputs;
    ras2 = import ./ras2.nix inputs;
    sawin-gallery = import ./sawin-gallery.nix inputs;
  };
  libraries = import ./libraries inputs;
}
