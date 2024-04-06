{
  pkgs,
  craneLib,
}: let
  mkRustPackage = import ../libs/nix/mkRustPackage.nix;
in
  mkRustPackage {
    inherit pkgs craneLib;
    srcPath = ../apps/rad;
    sourceFilter = path: type: craneLib.filterCargoSources path type || (builtins.match ".*/migrations/.*" path != null) || (builtins.match ".*/.sqlx/.*" path != null);
  }
