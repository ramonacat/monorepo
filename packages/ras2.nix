{pkgs, ...}: let
  packageAttributes = {
    php = pkgs.php82;

    pname = "ras2";
    version = "1.0.0";

    src = ../apps/ras2;

    # The composer vendor hash
    vendorHash = "sha256-U5cKlOQqyomAWfcMlfneZ5nm5iHRyFri2VeqY2FoUD8=";
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
  devPackage = pkgs.php.buildComposerProject (_: ({
      composerNoDev = false;
      composerNoScripts = false;
      php = devPhp;
    }
    // packageAttributes));
  nodeDependencies = pkgs.runCommand "${packageAttributes.pname}--composer-deps-all" {buildInputs = [pkgs.nodejs_22];} (let
    npmDeps = pkgs.importNpmLock {
      npmRoot = ../apps/ras2;
    };
  in ''
    mkdir $out
    cp ${npmDeps}/* .
    chmod 777 *.json

    export HOME="$TMPDIR"
    npm install

    cp -r ./* $out/
  '');
in rec {
  package = pkgs.php.buildComposerProject (_: packageAttributes);
  # FIXME: actually get the coverage here...
  coverage = pkgs.runCommand "${package.name}--coverage" {} "touch $out";
  checks = {
    "${package.name}--ecs" =
      pkgs.runCommand "${devPackage.name}--ecs" {
        buildInputs = [devPhp pkgs.bash pkgs.nodePackages.gulp-cli pkgs.nodejs_22];
      } ''
        mkdir -p $out/build/node_modules/
        cp -r ${devPackage}/share/php/ras2/* $out/build/
        cp -r ${nodeDependencies}/node_modules/* $out/build/node_modules/
        cd $out/build/
        chmod -R a+w .

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
