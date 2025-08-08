{
  pkgs,
  local-packages,
  ...
}: let
  source = pkgs.lib.cleanSource ./..;
  source-files = pkgs.lib.filesystem.listFilesRecursive source;
  all-shell-scripts =
    builtins.filter
    (x: (pkgs.lib.hasSuffix ".sh" x || pkgs.lib.hasSuffix ".bash" x) && !(pkgs.lib.strings.hasInfix "/vendor/" x))
    source-files;
  shell-scripts = pkgs.lib.escapeShellArgs all-shell-scripts;
in
  {
    fmt-nix = pkgs.runCommand "fmt-nix" {} ''
      ${pkgs.alejandra}/bin/alejandra --check ${source}

      touch $out
    '';
    fmt-lua = pkgs.runCommand "fmt-lua" {} ''
      ${pkgs.stylua}/bin/stylua --check ${source}

      touch $out
    '';
    fmt-bash = pkgs.runCommand "fmt-bash" {} ''
      ${pkgs.shfmt}/bin/shfmt -d ${shell-scripts}

      touch $out
    '';
    deadnix = pkgs.runCommand "deadnix" {} ''
      ${pkgs.deadnix}/bin/deadnix --fail ${source}

      touch $out
    '';
    statix = pkgs.runCommand "statix" {} ''
      ${pkgs.statix}/bin/statix check ${source}

      touch $out
    '';
    shellcheck = pkgs.runCommand "shellcheck" {} ''
      ${pkgs.shellcheck}/bin/shellcheck --source-path="${pkgs.lib.escapeShellArg "${source}"}" ${shell-scripts}

      touch $out
    '';
  }
  // (pkgs.lib.mergeAttrsList (
    pkgs.lib.mapAttrsToList (_: value: value.checks)
    (local-packages.libraries // local-packages.apps)
  ))
