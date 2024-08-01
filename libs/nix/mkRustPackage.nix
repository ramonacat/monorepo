{
  pkgs,
  craneLib,
  srcPath,
  additionalPackageArguments ? {},
  sourceFilter ? path: type: craneLib.filterCargoSources path type,
  buildAdditionalPackageArguments ? {},
}: let
  filteredSrc = pkgs.lib.cleanSourceWith {
    src = craneLib.path srcPath;
    filter = sourceFilter;
  };
  packageArguments =
    {
      src = filteredSrc;
    }
    // (
      if (builtins.isAttrs additionalPackageArguments)
      then additionalPackageArguments
      else (additionalPackageArguments {src = filteredSrc;})
    );
  buildAdditionalPackageArgumentsRealised =
    if builtins.isAttrs buildAdditionalPackageArguments
    then buildAdditionalPackageArguments
    else (buildAdditionalPackageArguments {src = filteredSrc;});
  cargoArtifacts = craneLib.buildDepsOnly packageArguments;
  packageArgumentsWithArtifacts = packageArguments // {inherit cargoArtifacts;};
in rec {
  package = craneLib.buildPackage (packageArguments
    // buildAdditionalPackageArgumentsRealised
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
