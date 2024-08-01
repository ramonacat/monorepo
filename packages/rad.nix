{
  pkgs,
  craneLib,
}: let
  mkRustPackage = import ../libs/nix/mkRustPackage.nix;
in
  mkRustPackage {
    inherit pkgs craneLib;
    srcPath = ../.;
    sourceFilter = path: type: (craneLib.filterCargoSources path type || (builtins.match ".*/migrations/.*" path != null) || (builtins.match ".*/.sqlx/.*" path != null));
    additionalPackageArguments = {src}: {
      sourceRoot = "${src.name}/apps/rad/";
      cargoToml = "${src}/apps/rad/Cargo.toml";
      cargoLock = "${src}/apps/rad/Cargo.lock";
    };
  }
