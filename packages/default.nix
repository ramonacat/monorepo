inputs: {
  apps =
    let
      ras2-attributes = {
        inherit (import ../data/package-versions.nix { inherit (inputs) pkgs; }) php;

        pname = "ras2";
        version = "1.0.0";

        src = ../apps/ras2;

        composerNoPlugins = false;
      };
    in
    {
      rad = import ./rad.nix inputs;
      ramona-fun = import ./ramona-fun.nix inputs;
      ras2 = import ./ras2.nix (inputs // { package-attributes = ras2-attributes; });
      ras2-dev = import ./ras2-dev.nix (inputs // { package-attributes = ras2-attributes; });
      sawin-gallery = import ./sawin-gallery.nix inputs;
    };
  libraries = import ./libraries inputs;
}
