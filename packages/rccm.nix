{ pkgs, ... }: rec {
  package = pkgs.buildGoModule {
    pname = "rccm";
    version = "1.0.0";
    src = ../apps/rccm;
    subPackges = [ "main" ];
    vendorHash = "sha256-HoXroTZFe1lST10l3ht+7AQUsg1x3rer9BB5BmfMyBA=";
  };
  coverage = pkgs.runCommand "${package.name}-coverage" { } "echo > $out";
  checks = { };
  container =
    let
      cacert = pkgs.cacert.override { extraCertificateFiles = [ ../certificates ]; };
    in
    pkgs.dockerTools.buildLayeredImage {
      name = "rccm";
      tag = "latest";
      contents = [
        package
        cacert
      ];
      config.Cmd = [ "/bin/rccm" ];
    };
}
