args: let
  mkRustPackage = import ./mkRustPackage.nix;
  package = mkRustPackage args;
in {
  checks = package.checks;
  coverage = package.coverage;
}
