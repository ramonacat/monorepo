args: let
  mkRustPackage = import ./mkRustPackage.nix;
  package = mkRustPackage args;
in {
  inherit (package) checks;
  inherit (package) coverage;
}
