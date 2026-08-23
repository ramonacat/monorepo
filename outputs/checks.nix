{
  pkgs,
  local-packages,
  ...
}:
(pkgs.lib.mergeAttrsList (pkgs.lib.mapAttrsToList (_: value: value.checks) local-packages.apps))
