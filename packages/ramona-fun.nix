{pkgs, ...}: rec {
  package = pkgs.stdenvNoCC.mkDerivation {
    name = "ramona.fun";
    src = ../apps/ramona.fun;
    buildPhase = "";
    installPhase = "mkdir $out/; cp -r ./* $out/";
  };
  coverage = pkgs.runCommand "${package.name}-coverage" {} "echo > $out";
  checks = {};
}
