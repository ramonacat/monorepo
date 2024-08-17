{pkgs, ...}: let
  rawPackage = pkgs.buildNpmPackage {
    name = "ratweb2";
    npmDeps = pkgs.importNpmLock {
      npmRoot = ../apps/ratweb2;
    };
    src = ../apps/ratweb2;
    buildPhase = ''
      npm run build
      mkdir $out/
      cp -r ./* $out/
    '';
    dontInstall = true;
    nodejs = pkgs.nodejs_22;

    inherit (pkgs.importNpmLock) npmConfigHook;
  };
in rec {
  package = pkgs.writeShellScriptBin "ratweb2" ''
    ${pkgs.nodejs_22}/bin/node ${rawPackage}/build
  '';
  coverage = pkgs.runCommand "${package.name}--coverage" {nativeBuildInputs = [pkgs.nodejs_22];} ''
    cp -r ${rawPackage}/* .
    chmod a+w node_modules/
    ./node_modules/.bin/vitest run

    mv coverage/clover.xml $out
  '';
  checks = {
    "${package.name}--check" = pkgs.runCommand "${package.name}--checks" {nativeBuildInputs = [pkgs.nodejs_22];} ''
      cp -r ${rawPackage}/* .
      npm run check

      mkdir $out/
    '';
  };
}
