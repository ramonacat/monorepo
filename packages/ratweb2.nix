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

    inherit (pkgs.nodePackages_latest) nodejs;
    inherit (pkgs.importNpmLock) npmConfigHook;
  };
in rec {
  package = pkgs.writeShellScriptBin "ratweb2" ''
    ${pkgs.nodePackages_latest.nodejs}/bin/node ${rawPackage}/build
  '';
  coverage = pkgs.runCommand "${package.name}--coverage" {nativeBuildInputs = [pkgs.nodePackages_latest.nodejs];} ''
    cp -r ${rawPackage}/* .
    chmod -R a+w ./node_modules/.vite-temp
    chmod a+w ./node_modules/
    mkdir ./node_modules/.vite
    chmod -R a+w ./node_modules/.vite
    ./node_modules/.bin/vitest run

    mv coverage/clover.xml $out
  '';
  checks = {
    "${package.name}--check" = pkgs.runCommand "${package.name}--checks" {nativeBuildInputs = [pkgs.nodePackages_latest.nodejs];} ''
      cp -r ${rawPackage}/* .
      chmod -R a+w ./node_modules/.vite-temp
      npm run check

      mkdir $out/
    '';
  };
}
