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
      cargoToml = ../apps/auth-proxy/Cargo.toml;
      cargoLock = ../apps/auth-proxy/Cargo.lock;
      nativeBuildInputs = [ pkgs.libpq.dev ];
      buildInputs = [ pkgs.libpq ];
      postUnpack = ''
        cd $sourceRoot/apps/auth-proxy
        sourceRoot="."
      '';
    };
  };
in
{
  inherit (package) coverage checks package;

  container =
    let
      cacert = pkgs.cacert.override { extraCertificateFiles = [ ../certificates ]; };
    in
    pkgs.dockerTools.buildLayeredImage {
      name = "auth-proxy";
      tag = "latest";
      contents = [ package.package ];
      config = {
        Cmd = [ "/bin/auth-proxy" ];
        Env = [ "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt" ];
      };

    };
}
