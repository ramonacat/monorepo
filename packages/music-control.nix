{
  pkgs,
  craneLib,
}: let
  mkRustPackage = import ../libs/nix/mkRustPackage.nix;
in
  mkRustPackage {
    inherit pkgs craneLib;
    srcPath = ../apps/ananas-music-control;
    sourceFilter = path: type: (craneLib.filterCargoSources path type || (builtins.match ".*/resources/.*" path != null));
    additionalPackageArguments = {
      buildInputs = with pkgs; [pkg-config alsa-lib.dev];
    };
  }
