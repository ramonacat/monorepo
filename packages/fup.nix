{ pkgs, ... }: rec {
  package = pkgs.stdenvNoCC.mkDerivation {
    name = "fup-1.0.0";
    nativeBuildInputs = with pkgs; [ makeWrapper ];
    src = ../apps/fup;
    installPhase = ''
      mkdir -p $out/bin
      cp fup $out/bin

      wrapProgram $out/bin/fup \
          --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [ backblaze-b2 ])}
    '';
  };
  coverage = pkgs.runCommand "${package.name}-coverage" { } "echo > $out";
  checks = { };
}
