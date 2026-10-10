{ pkgs, crane-lib, ... }:
let
  package = (import ../libs/nix/mk-rust-package.nix) {
    inherit pkgs;
    inherit crane-lib;

    src-path = ../.;
    source-filter =
      path: type:
      (
        crane-lib.filterCargoSources path type
        || (builtins.match ".*/migrations/.*" path != null)
        || (builtins.match ".*/.sqlx/.*" path != null)
      );
    additional-package-arguments = {
      cargoToml = ../apps/ras/Cargo.toml;
      cargoLock = ../apps/ras/Cargo.lock;
      nativeBuildInputs = [ pkgs.libpq.dev ];
      buildInputs = [ pkgs.libpq ];
      postUnpack = ''
        cd $sourceRoot/apps/ras
        sourceRoot="."
      '';
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
