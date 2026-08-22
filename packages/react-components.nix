{ pkgs, ... }:
let
  package-versions = import ../data/package-versions.nix { inherit pkgs; };
  package-options = {
    name = "ramona/react-components";
    npmDeps = pkgs.importNpmLock {
      npmRoot = ../libs/js/react-components;
    };
    src = ../libs/js/react-components;
    buildPhase = ''
      npm run build

      mkdir $out/
      cp -r ./* $out/
      rm -r $out/node_modules/
    '';

    inherit (package-versions) nodejs;
    inherit (pkgs.importNpmLock) npmConfigHook;
  };
  package = pkgs.buildNpmPackage package-options;
in
rec {
  inherit package;

  # TODO yuh, this really should have some tests
  coverage = pkgs.runCommand "${package.name}-coverage" { } "echo > $out";
  checks = { };
}
