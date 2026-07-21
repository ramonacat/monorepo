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
      pkgs.cacert
    ];
    config.Cmd = [
      "/bin/atticd"
      "--config"
      "/etc/attic.conf"
    ];
  };
}
