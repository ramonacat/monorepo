{ pkgs, ... }:
{
  # TODO should probably support just skipping package/coverage/checks as needed
  package = pkgs.runCommand "ci-package" { } "echo > $out";
  coverage = pkgs.runCommand "ci-coverage" { } "echo > $out";
  checks = { };
  container = pkgs.dockerTools.buildLayeredImageWithNixDb {
    name = "ci";
    tag = "latest";
    contents = pkgs.buildEnv {
      name = "ci";
      paths = with pkgs; [
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
        docker

        nix
        cacert
        gitMinimal
        gnutar
        gzip
        openssh
        xz
        iana-etc
      ];
      pathsToLink = [ "/bin" ];
    };
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
