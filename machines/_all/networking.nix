{lib, ...}: {
  config = {
    # this service does nothing useful but breaks rebuilds if it's restarted
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    networking = {
      useDHCP = lib.mkForce true;
      networkmanager.enable = true;
      wireless.enable = false;
      nftables.enable = true;
    };
  };
}
