{
  pkgs,
  craneLib,
}: let
  mkRustPackage = import ../libs/nix/mkRustPackage.nix;
in
  mkRustPackage {
    inherit pkgs craneLib;
    srcPath = ../.;
    additionalPackageArguments = {src}: {
      sourceRoot = "${src.name}/apps/rat/";
      cargoToml = "${src}/apps/rat/Cargo.toml";
      cargoLock = "${src}/apps/rat/Cargo.lock";
    };
  }
