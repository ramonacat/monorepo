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
  android = rec {
    composition = pkgs.androidenv.composeAndroidPackages {
      platformVersions = [
        "24"
        "37"
      ];
      buildToolsVersions = [ "36.0.0" ];
    };
    sdk = composition.androidsdk;
    jdk = pkgs.jdk25;
    gradle = pkgs.gradle_9;
  };
}
