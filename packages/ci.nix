{ pkgs, inputs, ... }:
{
  # TODO should probably support just skipping package/coverage/checks as needed
  package = pkgs.runCommand "ci-package" { } "echo > $out";
  coverage = pkgs.runCommand "ci-coverage" { } "echo > $out";
  checks = { };
  container = pkgs.dockerTools.buildLayeredImage {
    name = "ci";
    tag = "latest";
    copyToRoot = pkgs.buildEnv {
      name = "ci";
      paths = with pkgs; [
        inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default

        terraform
        tflint
        backblaze-b2
        shfmt
        attic-client
        bash
        coreutils
        util-linux
      ];
      pathsToLink = "/bin";
    };
    config = {
      Cmd = [
        "/bin/true"
      ];
      Env = [
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "PATH=/bin"
      ];
    };
  };
}
