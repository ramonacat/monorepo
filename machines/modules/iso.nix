{ lib, modulesPath, pkgs, config, ... }:
  { 
    nixpkgs.overlays = [(final: super: {
      zfs = super.zfs.overrideAttrs(_: {
        meta.platforms = [];
      });
    })];
  }