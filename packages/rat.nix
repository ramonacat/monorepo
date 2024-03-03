{
  pkgs,
  craneLib,
}: let
  packageArguments = {
    src = pkgs.lib.cleanSourceWith {
      src = craneLib.path ../apps/rat;
    };
    buildInputs = with pkgs; [
    ];
  };
  cargoArtifacts = craneLib.buildDepsOnly packageArguments;
in
  craneLib.buildPackage (packageArguments
    // {
      inherit cargoArtifacts;
    })
