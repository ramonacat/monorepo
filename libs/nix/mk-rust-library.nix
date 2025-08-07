args: let
  mk-rust-package = import ./mk-rust-package.nix;
  package = mk-rust-package args;
in {
  inherit (package) checks;
  inherit (package) coverage;
}
