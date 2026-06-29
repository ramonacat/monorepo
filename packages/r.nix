{ pkgs, crane-lib, ... }:
(import ../libs/nix/mk-rust-package.nix) {
  inherit pkgs;
  inherit crane-lib;

  src-path = ../apps/r;
  build-additional-package-arguments = {
    nativeBuildInputs = with pkgs; [
      installShellFiles
      openssl_4_0.dev
      pkg-config
    ];
    postInstall = ''
      installShellCompletion --cmd r \
          --bash <($out/bin/r completions bash) \
          --fish <($out/bin/r completions fish) \
          --zsh <($out/bin/r completions zsh)
    '';
  };
  additional-package-arguments = {
    nativeBuildInputs = with pkgs; [
      openssl_4_0.dev
      pkg-config
    ];
  };
}
