{
  pkgs,
  craneLib,
  srcPath,
  additionalPackageArguments ? {},
  sourceFilter ? path: type: craneLib.filterCargoSources path type,
}: let
  src = pkgs.lib.cleanSourceWith {
    src = craneLib.path srcPath;
    filter = sourceFilter;
  };
  packageArguments =
    {
      inherit src;
    }
    // (
      if (builtins.isAttrs additionalPackageArguments)
      then additionalPackageArguments
      else (additionalPackageArguments {inherit src;})
    );
  cargoArtifacts = craneLib.buildDepsOnly packageArguments;
  packageArgumentsWithArtifacts = packageArguments // {inherit cargoArtifacts;};
in rec {
  package = craneLib.buildPackage (packageArguments
    // {
      inherit cargoArtifacts;
    });
  checks = {
    "${package.name}--fmt" = craneLib.cargoFmt packageArguments;
    "${package.name}--clippy" = craneLib.cargoClippy packageArgumentsWithArtifacts;
  };

  coverage = let
    rawCoverage = craneLib.cargoLlvmCov ({cargoLlvmCovExtraArgs = "--lcov --output-path $out";} // packageArgumentsWithArtifacts);
  in
    pkgs.runCommand "${package.name}--coverage" {} ''
      cat ${rawCoverage} | sed "s#/build/source#${builtins.replaceStrings [((builtins.toString ../../.) + "/")] [""] (builtins.toString srcPath)}#g" > $out
    '';
}
