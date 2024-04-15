{
  pkgs,
  craneLib,
}: let
  mkRustPackage = import ../libs/nix/mkRustPackage.nix;
in
  mkRustPackage {
    inherit pkgs craneLib;
    srcPath = ../.;
    sourceFilter = path: type: craneLib.filterCargoSources path type || (builtins.match ".*/migrations/.*" path != null) || (builtins.match ".*/.sqlx/.*" path != null);
    additionalPackageArguments = {src}: {
      sourceRoot = "${src.name}/apps/ras/";
      cargoToml = "${src}/apps/ras/Cargo.toml";
      cargoLock = "${src}/apps/ras/Cargo.lock";
    };
  }
