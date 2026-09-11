{ pkgs, crane-lib, ... }:
let
  package = (import ../libs/nix/mk-rust-package.nix) {
    inherit pkgs;
    inherit crane-lib;

    src-path = ../apps/auth-proxy;
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
