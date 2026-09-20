{ pkgs, crane-lib, ... }:
let
  package = (import ../libs/nix/mk-rust-package.nix) {
    inherit pkgs;
    inherit crane-lib;

    src-path = ../.;
    source-filter =
      path: type:
      (crane-lib.filterCargoSources path type || (builtins.match ".*/migrations/.*" path != null));
    additional-package-arguments = {
      cargoToml = ../apps/rad/Cargo.toml;
      cargoLock = ../apps/rad/Cargo.lock;
      nativeBuildInputs = [ pkgs.libpq.dev ];
      buildInputs = [ pkgs.libpq ];
      postUnpack = ''
        cd $sourceRoot/apps/rad
        sourceRoot="."
      '';
    };
  };
in
{
  inherit (package) coverage checks package;

  container = pkgs.dockerTools.buildLayeredImage {
    name = "rad";
    tag = "latest";
    contents = [ package.package ];
    config.Cmd = [ "/bin/rad" ];
  };
}
