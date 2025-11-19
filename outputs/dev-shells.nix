{
  inputs,
  pkgs,
  package-versions,
  ...
}:
pkgs.mkShell {
  packages = with pkgs; [
    (stdenvNoCC.mkDerivation {
      name = "generate-syncthing-keys";
      src = ../scripts;
      nativeBuildInputs = [makeWrapper];
      installPhase = ''
        mkdir -p $out/bin/;

        cp generate-syncthing-keys.bash $out/bin/generate-syncthing-keys

        wrapProgram $out/bin/generate-syncthing-keys \
            --prefix PATH : "${lib.makeBinPath [jq syncthing xidel inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default]}"
      '';
    })

    (stdenvNoCC.mkDerivation {
      name = "make-preinstall-bundle";
      src = ../scripts;
      nativeBuildInputs = [makeWrapper];
      installPhase = ''
        mkdir -p $out/bin/;

        cp make-preinstall-bundle.bash $out/bin/make-preinstall-bundle

        wrapProgram $out/bin/make-preinstall-bundle \
            --prefix PATH : "${lib.makeBinPath [jq]}"
      '';
    })

    bash-language-server
    google-cloud-sdk
    nil
    nushell
    phpactor
    postgresql_16
    rust-analyzer
    shfmt
    terraform
    terraform-ls

    package-versions.nodejs
    package-versions.php-dev
    package-versions.php-packages.composer
    package-versions.rust-version
  ];
  RAMONA_FLAKE_ROOT = ./..;
}
