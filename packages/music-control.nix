{ pkgs, craneLib }:
let
  sourceFilter = path: type: craneLib.filterCargoSources path type || (builtins.match ".*/resources/.*" path != null);
  packageArguments = {
    src = pkgs.lib.cleanSourceWith {
      src = craneLib.path ../apps/ananas-music-control;
      filter = sourceFilter;
    };
    buildInputs = with pkgs; [
      pkg-config
      alsaLib.dev
    ];
  };
  cargoArtifacts = craneLib.buildDepsOnly packageArguments;
in
craneLib.buildPackage (packageArguments // {
  cargoArtifacts = cargoArtifacts;
})
