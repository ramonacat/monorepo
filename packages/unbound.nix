{ pkgs, ... }:
{
  # TODO should probably support just skipping package/coverage/checks as needed
  package = pkgs.runCommand "unbound-package" { } "echo > $out";
  coverage = pkgs.runCommand "unbound-coverage" { } "echo > $out";
  checks = { };
  container = pkgs.dockerTools.buildLayeredImage {
    name = "unbound";
    tag = "latest";
    contents = [
      pkgs.unbound
    ];
    config = {
      Cmd = [
        "/bin/unbound"
        "-c"
        "/var/ramona/unbound.conf"
        "-d"
        "-d"
      ];
      Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
    };
  };
}
