{pkgs, ...}: {
  config = {
    services.openssh.enable = true;
    programs.ssh.knownHosts = let
      ssh-keys = import ../../data/ssh-keys.nix;
    in
      builtins.listToAttrs (
        pkgs.lib.flatten (
          pkgs.lib.mapAttrsToList (hostname: keys: (pkgs.lib.mapAttrsToList (key-type: key: {
              name = "${hostname}/${key-type}";
              value = {
                hostNames = [hostname "${hostname}.ibis-draconis.ts.net"];
                publicKey = key;
              };
            })
            keys))
          ssh-keys.machines
        )
      );
  };
}
