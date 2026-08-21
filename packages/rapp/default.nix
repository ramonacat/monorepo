{ pkgs, ... }:
let
  inherit (import ../../data/package-versions.nix { inherit pkgs; }) android;
  inherit (android) jdk gradle;
  android-sdk = android.sdk;
in
rec {
  package = pkgs.stdenvNoCC.mkDerivation {
    pname = "rapp";
    version = "0.1.0";
    nativeBuildInputs = with pkgs; [
      gradle
      makeWrapper
      android-sdk
      jdk
    ];
    ANDROID_HOME = "${android-sdk}/libexec/android-sdk";
    gradleUpdateScript = ''
      runHook preBuild

      gradle --write-verification-metadata sha256
    '';
    gradleFlags = [
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android-sdk}/libexec/android-sdk/build-tools/36.0.0/aapt2"
      "-Dorg.gradle.java.home=${jdk}"
      "--info"
    ];
    src = ../../apps/rapp;
    mitmCache = gradle.fetchDeps {
      pkg = package;
      data = ./deps.json;
      useBwrap = false;
    };

    installPhase = ''
      runHook preInstall

      mkdir $out
      mv app/build/outputs/apk/release/app-release-unsigned.apk $out/release.apk
      mv app/build/outputs/apk/debug/app-debug.apk $out/debug.apk

      runHook postInstall
    '';
  };
  coverage = pkgs.runCommand "${package.name}-coverage" { } "echo > $out";
  checks = { };
}
