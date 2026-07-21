inputs: {
  apps = {
    attic = import ./attic.nix inputs;
    fup = import ./fup.nix inputs;
    r = import ./r.nix inputs;
    ramona-fun = import ./ramona-fun.nix inputs;
    ras = import ./ras.nix inputs;
    sawin-gallery = import ./sawin-gallery.nix inputs;
  };
  libs = {
    js = {
      react-components = import ./react-components.nix inputs;
    };
  };
}
