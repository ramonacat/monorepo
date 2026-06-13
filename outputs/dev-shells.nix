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

    (stdenvNoCC.mkDerivation {
      name = "generate-host-keys";
      src = ../scripts;
      nativeBuildInputs = [ makeWrapper ];
      installPhase = ''
        mkdir -p $out/bin/;

        cp generate-host-keys.bash $out/bin/generate-host-keys

        wrapProgram $out/bin/generate-host-keys \
            --prefix PATH : "${lib.makeBinPath [ ]}"
      '';
    })

    (pkgs.writeShellScriptBin "terraform" ''
      set -e

      export KUBECONFIG=$(mktemp)
      chown $(id -u):$(id -g) $KUBECONFIG
      cleanup() { rm $KUBECONFIG; }
      trap cleanup EXIT

      pushd "$RAMONA_FLAKE_ROOT/secrets/" >/dev/null
      set -a
      eval "$(agenix -d terraform-tokens.age)" >/dev/null
      set +a
      agenix -d darkmore-kubeconfig.age >$KUBECONFIG
      popd >/dev/null

      export KUBE_CONFIG_PATH="$KUBECONFIG"

      exec ${pkgs.terraform}/bin/terraform "$@"
    '')

    (pkgs.writeShellScriptBin "kubectl" ''
      set -e

      export KUBECONFIG=$(mktemp)
      chown $(id -u):$(id -g) $KUBECONFIG
      cleanup() { rm $KUBECONFIG; }
      trap cleanup EXIT

      pushd "$RAMONA_FLAKE_ROOT/secrets/" >/dev/null
      agenix -d darkmore-kubeconfig.age >$KUBECONFIG
      popd >/dev/null

      ${pkgs.kubernetes}/bin/kubectl "$@"
    '')

    age
    backblaze-b2
    fluxcd
    inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
    nushell
    postgresql_16
    shellcheck
    shfmt
    tflint

    package-versions.nodejs
    package-versions.php-dev
    package-versions.php-packages.composer
    package-versions.rust-version
  ];
  RAMONA_FLAKE_ROOT = ./..;
}
