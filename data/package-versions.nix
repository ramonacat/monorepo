{ pkgs }: {
  nodejs = pkgs.nodejs_latest;
  rust-version = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "rust-src"
      "llvm-tools-preview"
    ];
    targets = [
      "aarch64-unknown-linux-gnu"
      "wasm32-unknown-unknown"
    ];
  };
}
