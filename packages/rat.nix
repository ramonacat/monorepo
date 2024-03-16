{
  pkgs,
  craneLib,
}: let
  sourceFilter = path: type: craneLib.filterCargoSources path type;
  src = pkgs.lib.cleanSourceWith {
    src = craneLib.path ../.;
    filter = sourceFilter;
  };
  packageArguments = {
    inherit src;
    sourceRoot = "${src.name}/apps/rat/";
    cargoToml = "${src}/apps/rat/Cargo.toml";
    cargoLock = "${src}/apps/rat/Cargo.lock";
  };
  cargoArtifacts = craneLib.buildDepsOnly packageArguments;
in
  craneLib.buildPackage (packageArguments
    // {
      inherit cargoArtifacts;
    })
