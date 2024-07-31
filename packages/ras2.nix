{pkgs, ...}: let
  packageAttributes = {
    php = pkgs.php82;

    pname = "ras2";
    version = "1.0.0";

    src = ../apps/ras2;

    # The composer vendor hash
    vendorHash = "sha256-+KNIT4AWkzgVySW9MOZlEjOpaa6qUKNidFrWn2nXQqM=";
    composerNoPlugins = false;
  };
  devPhp = pkgs.php82.buildEnv {
    extensions = {
      enabled,
      all,
    }:
      enabled ++ [all.pcov];
    extraConfig = ''
    '';
  };
in rec {
  package = pkgs.php.buildComposerProject (_: packageAttributes);
  devPackage = pkgs.php.buildComposerProject (_: ({
      composerNoDev = false;
      composerNoScripts = false;
      php = devPhp;
    }
    // packageAttributes));
  # FIXME: actually get the coverage here...
  coverage = pkgs.runCommand "${package.name}--coverage" {} "touch $out";
  checks = {
    "${package.name}--ecs" =
      pkgs.runCommand "${devPackage.name}--ecs" {
        buildInputs = [devPhp pkgs.bash];
      } ''
        mkdir $out/
        cp -r ${devPackage}/share/php/ras2/* $out/
        cd $out

        # this is an awful hack
        # We generally want to allow nix to patch shebangs, but phars can have signatures
        # So we restore the signatures for phars manually here
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
