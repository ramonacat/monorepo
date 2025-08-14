{
  config,
  lib,
  ...
}: let
  syncthing-gui-port = 8384;
  syncthing-data = import ../../data/syncthing.nix;
  current-host-topology =
    lib.mapAttrs
    (_: hosts: lib.filterAttrs (k: _: k != config.networking.hostName) hosts)
    (
      lib.attrsets.filterAttrs
      (_: v: builtins.hasAttr config.networking.hostName v)
      syncthing-data.topology
    );
  enable = current-host-topology != {};
  settings =
    syncthing-data.settings.default
    // (
      if
        (
          builtins.hasAttr config.networking.hostName syncthing-data.settings
        )
      then (builtins.getAttr config.networking.hostName syncthing-data.settings)
      else {}
    );
  connected-devices =
    lib.filterAttrs
    (k: _: k != config.networking.hostName)
    (
      lib.mergeAttrsList (lib.mapAttrsToList (_: machines: machines) current-host-topology)
    );
in
  lib.mkIf enable {
    age.secrets."${config.networking.hostName}-syncthing-cert.age".file = ../../secrets + "/${config.networking.hostName}-syncthing-cert.age";
    age.secrets."${config.networking.hostName}-syncthing-key.age".file = ../../secrets + "/${config.networking.hostName}-syncthing-key.age";
    services.syncthing = {
      inherit (settings) user;
      enable = true;
      overrideDevices = true;
      overrideFolders = true;
      guiAddress = "0.0.0.0:${builtins.toString syncthing-gui-port}";
      key = config.age.secrets."${config.networking.hostName}-syncthing-key.age".path;
      cert = config.age.secrets."${config.networking.hostName}-syncthing-cert.age".path;
      # This does NOT open the gui port, we open it below only for the tailscale0 interface
      openDefaultPorts = true;
      settings = {
        devices = lib.mapAttrs (_: id: {inherit id;}) connected-devices;
        folders =
          lib.mapAttrs
          (
            id: hosts: {
              inherit id;
              inherit (settings.folders."${id}") path;

              devices = lib.mapAttrsToList (k: _: k) hosts;
            }
          )
          current-host-topology;
      };
      dataDir = lib.mkIf (settings ? dataDir) settings.dataDir;
      configDir = lib.mkIf (settings ? configDir) settings.configDir;
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [syncthing-gui-port];
  }
