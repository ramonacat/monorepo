{ pkgs, ... }:
{
  # TODO should probably support just skipping package/coverage/checks as needed
  package = pkgs.runCommand "attic-package" { } "echo > $out";
  coverage = pkgs.runCommand "attic-coverage" { } "echo > $out";
  checks = { };
  container = pkgs.dockerTools.buildLayeredImage {
    name = "attic";
    tag = "latest";
    contents = [
      pkgs.attic-server
    ];
    config = {
      Cmd = [
        "/bin/atticd"
        "--config"
        "/etc/attic.conf"
      ];
      Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
    };
  };
}
