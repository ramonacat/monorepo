{
  pkgs,
  craneLib,
}: let
  mkRustLibrary = import ../../libs/nix/mkRustLibrary.nix;
in
  mkRustLibrary {
    inherit pkgs craneLib;
    srcPath = ../../libs/rust/ratlib;
  }
