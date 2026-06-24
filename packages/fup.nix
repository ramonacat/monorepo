{ pkgs, ... }: rec {
  package = pkgs.stdenvNoCC.mkDerivation {
    name = "fup-1.0.0";
    buildInputs = with pkgs; [ backblaze-b2 ];
    src = ../apps/fup;
    installPhase = ''
      mkdir -p $out/bin
      cp fup $out/bin
    '';
  };
  coverage = pkgs.runCommand "${package.name}-coverage" { } "echo > $out";
  checks = { };
}
