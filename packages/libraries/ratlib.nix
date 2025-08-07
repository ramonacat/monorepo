{
  pkgs,
  crane-lib,
}: let
  mk-rust-library = import ../../libs/nix/mk-rust-library.nix;
in
  mk-rust-library {
    inherit pkgs crane-lib;
    src-path = ../../libs/rust/ratlib;
  }
