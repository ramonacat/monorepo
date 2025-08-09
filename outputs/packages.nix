{
  local-packages,
  pkgs,
  flake,
  ...
}:
rec {
  coverage = let
    paths = pkgs.lib.mapAttrsToList (_: value: value.coverage) (
      local-packages.libraries // local-packages.apps
    );
  in
    pkgs.runCommand "coverage" {} (
      "mkdir $out\n"
      + (pkgs.lib.concatStringsSep "\n" (builtins.map (p: "ln -s ${p} $out/${p.name}") paths))
      + "\n"
    );
  everything = let
    all-hosts = builtins.mapAttrs (_: value: value.config.system.build.toplevel) flake.nixosConfigurations;
    all-homes = builtins.mapAttrs (_: value: value.activationPackage) flake.homeConfigurations;
  in
    pkgs.runCommand "everything" {} (
      "mkdir -p $out/hosts\n"
      + (pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (k: p: "ln -s ${p} $out/hosts/${k}") all-hosts))
      + "\nmkdir -p $out/homes\n"
      + (pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (k: v: "ln -s ${v} $out/homes/${k}") all-homes))
      + "\nln -s ${flake.nixosConfigurations.iso.config.system.build.isoImage} $out/iso\n"
      + "\nln -s ${flake.nixosConfigurations.iso.config.formats.kexec-bundle} $out/kexec-bundle\n"
    );
  default = coverage;
}
// (builtins.mapAttrs (_: v: v.package) local-packages.apps)
