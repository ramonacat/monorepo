{ pkgs, ... }:
let
  package-versions = import ../data/package-versions.nix { inherit pkgs; };
  package-options = {
    name = "sawin.gallery";
    npmDeps = pkgs.importNpmLock {
      npmRoot = ../apps/sawin.gallery;
    };
    src = ../apps/sawin.gallery;
    buildPhase = ''
      npm run build
      mkdir $out/
      cp -r ./dist/* $out/
    '';

    inherit (package-versions) nodejs;
    inherit (pkgs.importNpmLock) npmConfigHook;
  };
  package = pkgs.buildNpmPackage (
    package-options
    // {
      buildPhase = ''
        npm run build
        mkdir $out/
        cp -r ./dist/* $out/
      '';
    }
  );
in
rec {
  inherit package;
  coverage = pkgs.runCommand "${package.name}-coverage" { } "echo > $out";
  checks = { };
}
