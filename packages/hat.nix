{
  pkgs,
  craneLib,
}: let
  mkRustPackage = import ../libs/nix/mkRustPackage.nix;
in
  mkRustPackage {
    inherit pkgs craneLib;
    srcPath = ../apps/hat;
    additionalPackageArguments = {
      buildInputs = with pkgs; [pkg-config udev.dev];
    };
  }
