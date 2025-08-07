{
  pkgs,
  crane-lib,
  src-path,
  additional-package-arguments ? {},
  source-filter ? path: type: crane-lib.filterCargoSources path type,
  build-additional-package-arguments ? {},
}: let
  filteredSrc = pkgs.lib.cleanSourceWith {
    src = crane-lib.path src-path;
    filter = source-filter;
  };
  packageArguments =
    {
      src = filteredSrc;
    }
    // (
      if (builtins.isAttrs additional-package-arguments)
      then additional-package-arguments
      else (additional-package-arguments {src = filteredSrc;})
    );
  buildAdditionalPackageArgumentsRealised =
    if builtins.isAttrs build-additional-package-arguments
    then build-additional-package-arguments
    else (build-additional-package-arguments {src = filteredSrc;});
  cargoArtifacts = crane-lib.buildDepsOnly packageArguments;
  packageArgumentsWithArtifacts = packageArguments // {inherit cargoArtifacts;};
in rec {
  package = crane-lib.buildPackage (packageArguments
    // buildAdditionalPackageArgumentsRealised
    // {
      inherit cargoArtifacts;
    });
  checks = {
    "${package.name}--fmt" = crane-lib.cargoFmt packageArguments;
    "${package.name}--clippy" = crane-lib.cargoClippy packageArgumentsWithArtifacts;
  };

  coverage = let
    rawCoverage = crane-lib.cargoLlvmCov ({cargoLlvmCovExtraArgs = "--lcov --output-path $out";} // packageArgumentsWithArtifacts);
  in
    pkgs.runCommand "${package.name}--coverage" {} ''
      cat ${rawCoverage} | sed "s#/build/source#${builtins.replaceStrings [((builtins.toString ../../.) + "/")] [""] (builtins.toString src-path)}#g" > $out
    '';
}
