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
      nativeBuildInputs = [ makeWrapper ];
      installPhase = ''
        mkdir -p $out/bin/;

        cp generate-syncthing-keys.bash $out/bin/generate-syncthing-keys

        wrapProgram $out/bin/generate-syncthing-keys \
            --prefix PATH : "${
              lib.makeBinPath [
                jq
                syncthing
                xidel
                inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
              ]
            }"
      '';
    })

    (stdenvNoCC.mkDerivation {
      name = "make-preinstall-bundle";
      src = ../scripts;
      nativeBuildInputs = [ makeWrapper ];
      installPhase = ''
        mkdir -p $out/bin/;

        cp make-preinstall-bundle.bash $out/bin/make-preinstall-bundle

        wrapProgram $out/bin/make-preinstall-bundle \
            --prefix PATH : "${lib.makeBinPath [ jq ]}"
      '';
    })

    google-cloud-sdk
    nushell
    postgresql_16
    shfmt
    backblaze-b2
    tflint

    (pkgs.writeShellScriptBin "terraform" ''
      pushd "$RAMONA_FLAKE_ROOT/secrets/"
      set -a
      eval "$(agenix -d terraform-tokens.age)" 
      set +a
      popd

      exec ${pkgs.terraform}/bin/terraform "$@"
    '')

    package-versions.nodejs
    package-versions.php-dev
    package-versions.php-packages.composer
    package-versions.rust-version
  ];
  RAMONA_FLAKE_ROOT = ./..;
}
