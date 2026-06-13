{ pkgs, packageAttributes, ... }:
let
  inherit (package-versions) php-dev;
  package-versions = import ../../data/package-versions.nix { inherit pkgs; };
in
php-dev.buildComposerProject (
  _:
  (
    packageAttributes
    // {
      pname = "ras2-dev";
      composerNoDev = false;
      composerNoScripts = false;
      php = php-dev;
      vendorHash = "sha256-hhehBhGKeSZZiK6nGmi4j4FtmDdR5y7DogCfknpIHAA=";
    }
  )
)
