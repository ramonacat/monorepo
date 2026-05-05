inputs: {
  apps = {
    rad = import ./rad.nix inputs;
    ramona-fun = import ./ramona-fun.nix inputs;
    ras2 = import ./ras2.nix inputs;
    sawin-gallery = import ./sawin-gallery.nix inputs;

    twiggy-language-server = import ./twiggy-langauge-server.nix inputs;
  };
  libraries = import ./libraries inputs;
}
