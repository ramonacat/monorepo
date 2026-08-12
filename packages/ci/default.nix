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
      terraform
      tflint
      backblaze-b2
      shfmt
      attic-client
      bash
      coreutils
      util-linux
      skopeo
      jq
      rclone
      curl

      nix
      cacert
      gitMinimal
      gnutar
      gzip
      openssh
      xz
      iana-etc

      package
    ];
    extraCommands = ''
      mkdir usr
      ln -s ../bin usr/bin

      mkdir -m 1777 tmp
      # skopeo insists on using this
      mkdir -m 1777 -p var/tmp

      mkdir -vp root
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
      ];
    };
  };
}
