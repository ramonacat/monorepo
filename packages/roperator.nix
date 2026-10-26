{ pkgs, crane-lib, ... }:
let
  package = (import ../libs/nix/mk-rust-package.nix) {
    inherit pkgs;
    inherit crane-lib;

    src-path = ../.;
    source-filter = path: type: (crane-lib.filterCargoSources path type);
    additional-package-arguments = {
      cargoToml = ../apps/roperator/Cargo.toml;
      cargoLock = ../apps/roperator/Cargo.lock;
      nativeBuildInputs = [ pkgs.libpq.dev ];
      buildInputs = [ pkgs.libpq ];
      postUnpack = ''
        cd $sourceRoot/apps/roperator
        sourceRoot="."
      '';
    };
  };
in
{
  inherit (package) coverage checks package;

  container = pkgs.dockerTools.buildLayeredImage {
    name = "roperator";
    tag = "latest";
    contents = [ package.package ];
    config = {
      Cmd = [ "/bin/roperator" ];
      Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
    };
  };
}
