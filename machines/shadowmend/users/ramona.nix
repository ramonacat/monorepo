{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    users.users.ramona.extraGroups = ["docker"];
  };
}
