{ pkgs, crane-lib, ... }:
let
  package = (import ../libs/nix/mk-rust-package.nix) {
    inherit pkgs;
    inherit crane-lib;

    src-path = ../apps/ras;
    source-filter =
      path: type:
      (crane-lib.filterCargoSources path type || (builtins.match ".*/migrations/.*" path != null));
    additional-package-arguments = {
      nativeBuildInputs = [ pkgs.libpq.dev ];
      buildInputs = [ pkgs.libpq ];
    };
  };
in
{
  inherit (package) coverage checks package;

  container = pkgs.dockerTools.buildLayeredImage {
    name = "ras";
    tag = "latest";
    contents = [ package.package ];
    config.Cmd = [ "/bin/ras" ];
  };
}
