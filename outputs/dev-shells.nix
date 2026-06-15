{
  inputs,
  pkgs,
  package-versions,
  ...
}:
pkgs.mkShell {
  packages =
    with pkgs;
    let
      prepare-kube-config = ''
        export KUBECONFIG=$(mktemp)
        chown $(id -u):$(id -g) $KUBECONFIG
        cleanup() { rm $KUBECONFIG; }
        trap cleanup EXIT

        pushd "$RAMONA_FLAKE_ROOT/secrets/" >/dev/null
        agenix -d darkmore-kubeconfig.age >$KUBECONFIG
        popd >/dev/null

        export KUBE_CONFIG_PATH="$KUBECONFIG"
      '';
    in
    [
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

        pushd "$RAMONA_FLAKE_ROOT/secrets/" >/dev/null
        set -a
        eval "$(agenix -d terraform-tokens.age)" >/dev/null
        set +a
        popd >/dev/null

        ${prepare-kube-config}

        ${pkgs.terraform}/bin/terraform "$@"
      '')

      (pkgs.writeShellScriptBin "kubectl" ''
        set -e

        ${prepare-kube-config}
        ${pkgs.kubernetes}/bin/kubectl "$@"
      '')

      (pkgs.writeShellScriptBin "argocd" ''
        set -e

        ${prepare-kube-config}
        ${pkgs.argocd}/bin/argocd "$@"
      '')

      age
      backblaze-b2
      inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
      postgresql_16
      shellcheck
      shfmt
      tflint
      argocd

      package-versions.nodejs
      package-versions.rust-version
    ];
  RAMONA_FLAKE_ROOT = ./..;
}
