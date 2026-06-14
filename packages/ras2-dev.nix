{ pkgs, package-attributes, ... }:
let
  inherit (package-versions) php-dev;
  package-versions = import ../data/package-versions.nix { inherit pkgs; };
in
rec {
  package = php-dev.buildComposerProject (
    _:
    (
      package-attributes
      // {
        pname = "ras2-dev";
        composerNoDev = false;
        composerNoScripts = false;
        php = php-dev;
        vendorHash = "sha256-hhehBhGKeSZZiK6nGmi4j4FtmDdR5y7DogCfknpIHAA=";
      }
    )
  );
  coverage = pkgs.runCommand "${package.name}-coverage" { } "echo > $out";
  checks = { };
}
