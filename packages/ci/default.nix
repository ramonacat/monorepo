{ pkgs, ... }:
{
  # TODO should probably support just skipping package/coverage/checks as needed
  package = pkgs.runCommand "ci-package" { } "echo > $out";
  coverage = pkgs.runCommand "ci-coverage" { } "echo > $out";
  checks = { };
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

      (pkgs.stdenvNoCC.mkDerivation {
        name = "scripts";
        src = ./scripts;
        nativeBuildInputs = [ makeWrapper ];

        installPhase = ''
          mkdir -p $out/bin/

          cp prepare-ci.bash $out/bin/prepare-ci
          cp download-cache.bash $out/bin/download-cache
          cp upload-cache.bash $out/bin/upload-cache

          wrapProgram $out/bin/prepare-ci \
            --prefix PATH : "${
              lib.makeBinPath [
                attic-client
                rclone
                openssh
                skopeo
              ]
            }"
          wrapProgram $out/bin/download-cache \
            --prefix PATH : "${
              lib.makeBinPath [
                rclone
              ]
            }"
          wrapProgram $out/bin/upload-cache \
            --prefix PATH : "${
              lib.makeBinPath [
                rclone
              ]
            }"
        '';
      })
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
