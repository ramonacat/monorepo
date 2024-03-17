args @ {
  pkgs,
  craneLib,
  srcPath,
  additionalPackageArguments ? {},
  sourceFilter ? path: type: craneLib.filterCargoSources path type,
}: let
  mkRustPackage = import ./mkRustPackage.nix;
  package = mkRustPackage args;
in {
  checks = package.checks;
  coverage = package.coverage;
}
