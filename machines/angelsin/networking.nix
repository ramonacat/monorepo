{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    networking.hostName = "angelsin";
    networking.enableIPv6 = false;
  };
}
