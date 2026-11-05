{ pkgs, crane-lib, ... }:
let
  package = (import ../../libs/nix/mk-rust-package.nix) {
    inherit pkgs;
    inherit crane-lib;

    src-path = ../../.;
    source-filter =
      path: type:
      (
        crane-lib.filterCargoSources path type
        || (builtins.match ".*/migrations/.*" path != null)
        || (builtins.match ".*/.sqlx/.*" path != null)
        || (builtins.match ".*/templates/.*" path != null)
      );
    additional-package-arguments = {
      cargoToml = ../../apps/rdns/Cargo.toml;
      cargoLock = ../../apps/rdns/Cargo.lock;
      nativeBuildInputs = with pkgs; [
        rustPlatform.bindgenHook
      ];
      buildInputs = [ pkgs.libpq ];
      postUnpack = ''
        cd $sourceRoot/apps/rdns
        sourceRoot="."
      '';
    };
  };
in
{
  inherit (package) coverage checks package;

  container = pkgs.dockerTools.buildLayeredImage {
    name = "rdns";
    tag = "latest";
    contents = [
      ./root
      package.package
      pkgs.nsd
    ];
    config.Cmd = [ "/bin/rdns" ];
    extraCommands = ''
      mkdir -m 1777 tmp
    '';
  };
}
