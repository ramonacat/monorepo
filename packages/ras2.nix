{pkgs, ...}: let
  inherit (package-versions) php;
  package-versions = import ../data/package-versions.nix {inherit pkgs;};
  packageAttributes = {
    inherit php;

    pname = "ras2";
    version = "1.0.0";

    src = ../apps/ras2;

    vendorHash = "sha256-5d/fVzMOGW8fWM6wiNpEADud+iQJmobnJgVqjiIr/Hk=";
    composerNoPlugins = false;
  };
  devPhp = package-versions.php-dev;
  devPackage = php.buildComposerProject (_: ({
      composerNoDev = false;
      composerNoScripts = false;
      php = devPhp;
    }
    // packageAttributes));
in rec {
  package = php.buildComposerProject (_: packageAttributes);
  coverage = let
    rawCoverage = pkgs.runCommand "${package.name}--coverage" {buildInputs = [devPhp];} "
  cd ${devPackage}/share/php/ras2/
  php ./vendor/bin/phpunit --coverage-clover $out
  ";
  in
    pkgs.runCommand "${devPackage.name}--clover" {} ''
      cat ${rawCoverage} | sed "s#${devPackage}/share/php/#apps/#g" > $out
    '';
  checks = {
    "${package.name}--ecs" =
      pkgs.runCommand "${devPackage.name}--ecs" {
        buildInputs = [devPhp pkgs.bash package-versions.nodejs];
      }
      ''
        mkdir -p $out

        cp -r ${devPackage}/share/php/ras2/* $out/

        cd $out/

        php ./vendor/bin/ecs
        # TODO this is causing: Fatal error: Uncaught PharException: manifest cannot be larger than 100 MB in phar "/nix/store/3axxd4wvid41yx5nvpmpiirn2rqw61vk-ras2-1.0.0--ecs/vendor/phpstan/phpstan/phpstan.phar" in /nix/store/3axxd4wvid41yx5nvpmpiirn2rqw61vk-ras2-1.0.0--ecs/vendor/phpstan/phpstan/phpstan:6
        # php ./vendor/bin/phpstan
        php ./vendor/bin/phpunit
        php ./vendor/bin/infection --min-msi=48 --min-covered-msi=100 -j"$(nproc)"
      '';
  };
}
