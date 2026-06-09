{
  pkgs,
  crane-lib,
  ...
}:
let
  mk-rust-library = import ../../libs/nix/mk-rust-library.nix;
in
mk-rust-library {
  inherit pkgs crane-lib;

  src-path = ../../.;
  additional-package-arguments = {
    pname = "ratlib-1.0.0";
    version = "1.0.0";
    cargoExtraArgs = "-p ratlib";
  };
}
