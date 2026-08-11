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

      nix
      cacert
      gitMinimal
      gnutar
      gzip
      openssh
      xz
      iana-etc

      (pkgs.writeShellScriptBin "prepare-ci" ''
        set -euo pipefail

        mkdir -p /etc/nix/
        mkdir -p ~/.ssh/
        mkdir -p ~/.config/rclone/

        attic login main https://attic.infrastructure.ramona.fun/ "$ATTIC_TOKEN"

        echo "extra-experimental-features = flakes nix-command" >> /etc/nix/nix.conf
        echo "$SSH_KEY" > ~/.ssh/id_ed25519 && chmod 0600 ~/.ssh/id_ed25519 && ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub

        echo > ~/.config/rclone/rclone.conf <<-EOT
        [default]
        type=s3
        provider=Hetzner
        access_key_id=$ACCESS_KEY_ID
        secret_access_key=$SECRET_ACCESS_KEY
        region=nbg1
        endpoint=nbg1.your-objectstorage.com
        EOT
      '')
    ];
    extraCommands = ''
      mkdir usr
      ln -s ../bin usr/bin

      mkdir -m 1777 tmp
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
