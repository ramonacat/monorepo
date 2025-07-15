{pkgs, ...}: let
  packageAttributes = {
    php = pkgs.php83;

    pname = "ras2";
    version = "1.0.0";

    src = ../apps/ras2;

    vendorHash = "sha256-qddMMVqLdjpa7W5bAQSsuXukjPxyfkv1XWhBuVxrgFY=";
    composerNoPlugins = false;
  };
  devPhp = pkgs.php83.buildEnv {
    extensions = {
      enabled,
      all,
    }:
      enabled ++ [all.xdebug];
    extraConfig = ''
      xdebug.mode=coverage
      memory_limit=1G
    '';
  };
  devPackage = pkgs.php.buildComposerProject (_: ({
      composerNoDev = false;
      composerNoScripts = false;
      php = devPhp;
    }
    // packageAttributes));
in rec {
  package = pkgs.php.buildComposerProject (_: packageAttributes);
  # FIXME: actually get the coverage here...
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
        buildInputs = [devPhp pkgs.bash pkgs.nodejs_22];
      } ''
        mkdir $out
        cp -r ${devPackage}/share/php/ras2/* $out/
        cd $out/

        # this is an awful hack
        # We generally want to allow nix to patch shebangs, but phars can have signatures
        # So we restore the shebangs for phars manually here, so the signatures match
        chmod a+w vendor/phpstan/phpstan/
        chmod a+w vendor/phpstan/phpstan/phpstan.phar
        sed -i "1s/.*/#!\\/usr\\/bin\\/env php/" vendor/phpstan/phpstan/phpstan.phar

        chmod a+w vendor/psalm/phar/
        chmod a+w vendor/psalm/phar/psalm.phar
        sed -i "1s/.*/#!\\/usr\\/bin\\/env php/" vendor/psalm/phar/psalm.phar

        bash ${../apps/ras2/build.sh} --no-fix
      '';
  };
}
