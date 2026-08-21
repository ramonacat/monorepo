{
  pkgs,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
  ...
}:
let
  project-root = ../../apps/ci;
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = project-root; };
  overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };
  python-set =
    (pkgs.callPackage pyproject-nix.build.packages { python = pkgs.python3; }).overrideScope
      (
        pkgs.lib.composeManyExtensions [
          pyproject-build-systems.overlays.wheel
          overlay
        ]
      );
  package-versions = import ../../data/package-versions.nix { inherit pkgs; };
in
rec {
  # TODO should probably support just skipping package/coverage/checks as needed
  package = python-set.mkVirtualEnv "ci-env" workspace.deps.default;
  coverage = pkgs.runCommand "ci-coverage" { } "echo > $out";
  checks = {
    ci-black =
      pkgs.runCommand "ci-black" { }
        "${pkgs.python3Packages.black}/bin/black --check ${project-root} && echo > $out";
  };
  container = pkgs.dockerTools.buildLayeredImageWithNixDb {
    name = "ci";
    tag = "latest";
    contents = with pkgs; [
      ./root

      age
      agenix
      (pkgs.writeShellScriptBin "terraform" ''
        set -euo pipefail

        set -a
        eval "$(${pkgs.age}/bin/age --decrypt --identity "$HOME/.ssh/id_ed25519" "$(git rev-parse --show-toplevel)/secrets/terraform-tokens.age")"
        set +a

        export KUBECONFIG=$(mktemp)
        chown $(id -u):$(id -g) "$KUBECONFIG"
        cleanup() { rm "$KUBECONFIG" || true; }
        trap cleanup EXIT

        ${pkgs.age}/bin/age --decrypt --identity "$HOME/.ssh/id_ed25519" --output "$KUBECONFIG" "$(git rev-parse --show-toplevel)/secrets/terraform-tokens.age"

        ${pkgs.terraform}/bin/terraform "$@"
      '')
      tflint
      backblaze-b2
      attic-client

      openssl_4_0.dev

      postgresql_18.dev

      coreutils
      curl
      findutils
      jq
      pkg-config
      skopeo
      util-linux

      bash
      shellcheck
      shfmt

      nodejs_26

      rustc
      cargo
      rustfmt
      clippy
      clang

      cacert
      gitMinimal
      gnutar
      gzip
      iana-etc
      nix
      openssh
      xz

      python3Packages.python
      python3Packages.uv

      package-versions.android.gradle
      package-versions.android.jdk
      package-versions.android.sdk
      ktfmt

      package
    ];
    extraCommands = ''
      mkdir usr
      ln -s ../bin usr/bin

      mkdir -m 1777 tmp
      # skopeo insists on using this
      mkdir -m 1777 -p var/tmp
      # android builds insist on using this
      mkdir -m 1777 -p var/empty

      mkdir -vp root/
      mkdir -vp root/.ssh/
      mkdir -vp root/.config/rclone/
    '';
    config = {
      Cmd = [
        "/bin/true"
      ];
      Env = [
        "ENV=/etc/profile.d/nix.sh"
        "BASH_ENV=/etc/profile.d/nix.sh"
        "NIX_BUILD_SHELL=/bin/bash"
        "PAGER=cat"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "PATH=/usr/bin:/bin"
        "USER=root"
        "HOME=/root"
        "PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.postgresql_18.dev}/lib/pkgconfig"
        "ANDROID_HOME=${package-versions.android.sdk}/libexec/android-sdk"
        "JAVA_HOME=${package-versions.android.jdk.home}"
      ];
    };
  };
}
