{
  pkgs,
  crane-lib,
}: let
  mk-rust-package = import ../libs/nix/mk-rust-package.nix;
in
  mk-rust-package {
    inherit pkgs crane-lib;
    src-path = ../.;
    source-filter = path: type: (crane-lib.filterCargoSources path type || (builtins.match ".*/migrations/.*" path != null) || (builtins.match ".*/.sqlx/.*" path != null));
    additional-package-arguments = {src}: {
      sourceRoot = "${src.name}/apps/rad/";
      cargoToml = "${src}/apps/rad/Cargo.toml";
      cargoLock = "${src}/apps/rad/Cargo.lock";
    };
  }
